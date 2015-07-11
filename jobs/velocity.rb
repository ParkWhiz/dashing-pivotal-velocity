require 'tracker_api'

# This sends events for each of these projects
# to widgets with IDs of 'pivotal-<project_id>' (e.g. 'pivotal-1133342')
projects = [999999,999998]

@client = TrackerApi::Client.new(token: ENV['PIVOTAL_API_TOKEN'])

def get_velocities(project_id)
  project = @client.project(project_id, fields: ':default,current_volatility')

  iterations = project.iterations(fields: 'start,stories(estimate)')
  iterations.map.with_index(1) do |iteration, x|
    {
      #"start" => iteration.start.strftime("%b %d"),
      "x"     => x,
      "y"     => iteration.stories.reduce(0) { |points,story| points += (story.estimate || 0) }
    }
  end
end

SCHEDULER.every '10m', :first_in => 0 do
  projects.each do |project_id|
    velocities = get_velocities(project_id)
    send_event("pivotal-#{project_id}", points: velocities, displayedValue: velocities[-2]["y"])
  end
end
