WIDTH = 1280
HEIGHT = 720
BACKGROUND = colorant"antiquewhite"

# birds are represented as a circle
RADIUS = 2

# random color for each birds 
COLORS = [colorant"red", colorant"green", colorant"blue"]

# number of birds
N = 200

# starting point in the plane for the n birds 
# i.e. each bird is affected to a random (x,y)
# rand(start:step:stop, number of random numbers to return as an array)
x = rand(20:5:(WIDTH - 20), N)
y = rand(20:5:(HEIGHT - 20), N)

# initial state 
birds = []
birds_color = []

# add each bird to our initial state
for i in 1:N
  push!(birds, Circle(x[i], y[i], RADIUS))
end

# give a color to each bird
for i in 1:N
  push!(birds_color, rand(COLORS))
end

# render birds on screen
function draw(g::Game)
  for i in 1:N 
    draw(birds[i], birds_color[i], fill = true)
  end
end

# random initial velocities
range = [collect(-4:-2); collect(2:4)]

vx = rand(range, N)
vy = rand(range, N)

# initial accelerations
ax = zeros(N)
ay = zeros(N)

# create steering forces (3 because 3 steering rules -- see below)
sep_rule_x = zeros(N)
sep_rule_y = zeros(N)

align_rule_x = zeros(N)
align_rule_y = zeros(N)

cohes_rule_x = zeros(N)
cohes_rule_y = zeros(N)

# make birds appear to other side of the screen of they go across a border 
function border(i)
  if birds[i].x > WIDTH
    birds[i].x = 0
  elseif birds[i].x < 0
    birds[i].x = WIDTH
  elseif birds[i].y > HEIGHT
    birds[i].y = 0
  elseif birds[i].y < 0
    birds[i].y = HEIGHT
  end
end 

# create a distance method
function distance(bird1::Circle, bird2::Circle)
  # GameZero need "integer" positions
  norm = Int(round(sqrt( (bird2.x - bird1.x)^2 + (bird2.y - bird1.y)^2 )))
  return norm
end 

# set variable for birds

# neighborhood radius
perception_radius = 10

# "importance" of the steering rules
separation_dial = 60
alignement_dial = 8
cohesion_dial = 100

# min and max speed for more fluid simulation
min_speed = 2
max_speed = 4

# flocking is basically based on 3 steering rules : https://www.red3d.com/cwr/boids/
function flock()
  # 1. separation : bird steer to avoid crowding local flockmates
  separation_forces_x = [] # x distance between 2 neighboor bird 
  separation_forces_y = [] # y distance between 2 neighboor bird 

  # 2. alignement : bird steer towards the "average heading" of local flockmates
  neighbor_vx = [] # x velocity of a neighboor bird
  neighbor_vy = [] # y velocity of a neighboor bird

  # 3. cohesion : bird steer to move toward the average position of local flockmates 
  neighbor_x = [] # x coordinate of a neighboor bird
  neighbor_y = [] # y coordinate of a neighboor bird

  # count number of neighboors
  total = 0

  for i in 1:N
    for j in 1:N
      # we only look at a neighborhood around the bird 
      d = distance(birds[i], birds[j])
      if (birds[i] !== birds[j]) && d < perception_radius

        # 1. populate array for separation rule 
        if birds[i].x !== birds[j].x
          s_f_x = birds[i].x - birds[j].x
        else 
          s_f_x = 0
        end 
      
        if birds[i].y !== birds[j].y 
          s_f_y = birds[i].y - birds[j].y
        else 
          s_f_y = 0
        end

        push!(separation_forces_x, s_f_x)
        push!(separation_forces_y, s_f_y)

        # 2. populate array for alignement rule
        push!(neighbor_vx, vx[j])
        push!(neighbor_vy, vy[j])

        # 3. populate array for cohesion rule
        push!(neighbor_x, birds[j].x)
        push!(neighbor_y, birds[j].y)

        total += 1
        
        # if any neighboors, apply rules
        if total > 0

          # 1. apply separation rule

          # compute mean distance between bird and his neighboors
          avg_x = Int(round( sum(separation_forces_x) / total ))
          avg_y = Int(round( sum(separation_forces_y) / total ))

          sep_steering_force_x = Int(round( (avg_x - vx[i]) / separation_dial ))
          sep_steering_force_y = Int(round( (avg_y - vy[i]) / separation_dial ))
          
          # adjust steering force for more fluid simulation
          if abs(sep_steering_force_x) < 1
            sep_steering_force_x = Int(round( min_speed * sign(sep_steering_force_x) ))
          end

          if abs(sep_steering_force_y) < 1
            sep_steering_force_y = Int(round( min_speed * sign(sep_steering_force_y) ))
          end

          if abs(sep_steering_force_x) > max_speed
            sep_steering_force_x = Int(round( max_speed * sign(sep_steering_force_x) ))
          end

          if abs(sep_steering_force_y) > max_speed
            sep_steering_force_y = Int(round( max_speed * sign(sep_steering_force_y) ))
          end

          sep_rule_x[i] = sep_steering_force_x
          sep_rule_y[i] = sep_steering_force_y

          # 2. apply alignement rule

          # compute mean velocity between bird and his neighboors
          avg_vx = Int(round( sum(neighbor_vx) / total ))
          avg_vy = Int(round( sum(neighbor_vy) / total ))

          align_steering_force_x = Int(round( (avg_vx - vx[i]) / separation_dial ))
          align_steering_force_y = Int(round( (avg_vy - vy[i]) / separation_dial ))

          # adjust steering force for more fluid simulation
          if abs(align_steering_force_x) < 1
            align_steering_force_x = Int(round( min_speed * sign(align_steering_force_x) ))
          end

          if abs(align_steering_force_y) < 1
            align_steering_force_y = Int(round( min_speed * sign(align_steering_force_y) ))
          end

          if abs(align_steering_force_x) > max_speed
            align_steering_force_x = Int(round( max_speed * sign(align_steering_force_x) ))
          end

          if abs(align_steering_force_y) > max_speed
            align_steering_force_y = Int(round( max_speed * sign(align_steering_force_y) ))
          end

          align_rule_x[i] = align_steering_force_x
          align_rule_y[i] = align_steering_force_y

          # 3. apply the cohesion rule

          # compute mean position between bird and his neighboors
          avg_position_x = Int(round( sum(neighbor_x) / total ))
          avg_position_y = Int(round( sum(neighbor_y) / total ))

          cohes_steering_force_x = Int(round( (avg_position_x - birds[i].x - vx[i]) / cohesion_dial ))
          cohes_steering_force_y = Int(round( (avg_position_y - birds[i].y - vy[i]) / cohesion_dial ))

          # adjust steering force for more fluid simulation
          if abs(cohes_steering_force_x) < 1
            cohes_steering_force_x = Int(round( min_speed * sign(cohes_steering_force_x) ))
          end

          if abs(cohes_steering_force_y) < 1
            cohes_steering_force_y = Int(round( min_speed * sign(cohes_steering_force_y) ))
          end

          if abs(cohes_steering_force_x) > max_speed
            cohes_steering_force_x = Int(round( max_speed * sign(cohes_steering_force_x) ))
          end

          if abs(cohes_steering_force_y) > max_speed
            cohes_steering_force_y = Int(round( max_speed * sign(cohes_steering_force_y) ))
          end

          cohes_rule_x[i] = cohes_steering_force_x
          cohes_rule_y[i] = cohes_steering_force_y

        end
      end
    end
  end
end

# update position of birds 
function update(g::Game)
  global sep_rule_x, sep_rule_y, align_rule_x, align_rule_y, cohes_rule_x, cohes_rule_y
  flock()

  for i in 1:N
    border(i)

    # compute accelerations
    ax[i] = sep_rule_x[i] + align_rule_x[i] + cohes_rule_x[i]
    ay[i] = sep_rule_y[i] + align_rule_y[i] + cohes_rule_y[i]

    # update velocities

    vx[i] += ax[i]
    vy[i] += ay[i]

    if vx[i] == 0
      vx[i] = min_speed * rand((-1, 1))
    end

    if vy[i] == 0
      vy[i] = min_speed * rand((-1, 1))
    end

    if abs(vx[i]) > max_speed
      vx[i] = max_speed * sign(vx[i])
    end

    if abs(vy[i]) > max_speed
      vy[i] = max_speed * sign(vy[i])
    end

    # update positions
    birds[i].x += vx[i]
    birds[i].y += vy[i]
  end

  # reset steering rules arrays
  sep_rule_x = zeros(N)
  sep_rule_y = zeros(N)
  
  align_rule_x = zeros(N)
  align_rule_y = zeros(N)
  
  cohes_rule_x = zeros(N)
  cohes_rule_y = zeros(N)

end