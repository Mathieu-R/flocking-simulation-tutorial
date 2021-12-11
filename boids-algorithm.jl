WIDTH = 1920
HEIGHT = 1080
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

# create steering forces 
rx1 = zeros(N)
ry1 = zeros(N)

rx2 = zeros(N)
ry2 = zeros(N)

rx3 = zeros(N)
ry3 = zeros(N)

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
perception_radius = 10
min_speed = 2
max_speed = 4
separation_dial = 60
alignement_dial = 8
cohesion = 100