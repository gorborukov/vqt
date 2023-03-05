module quadtree

import rand

pub struct Bounds {
pub:
  x f64
  y f64
  width f64
  height f64
}

pub struct Quadtree {
pub mut:
  bounds Bounds
  max_objects int
  max_levels int
  level int
  objects []Bounds
  nodes []Quadtree
  total int
}

fn (b Bounds) is_point() bool {
  if b.width == 0 && b.height == 0 {
    return true
  }
  return false
}

fn (b &Bounds) intersects(a Bounds) bool {
  a_max_x := a.x + a.width
  a_max_y := a.y + a.height
  b_max_x := b.x + b.width
  b_max_y := b.y + b.height

  if a_max_x < b.x {
    return false
  }

  if a.x > b_max_x {
    return false
  }

  if a_max_y < b.y {
    return false
  }

  if a.y > b_max_y {
    return false
  }

  return true
}

pub fn (qt &Quadtree) total_nodes() int {
  mut total := 0
  if qt.nodes.len > 0 {
    for i := 0; i < qt.nodes.len; i++ {
      total += 1
      total += qt.nodes[i].total_nodes()
    }
  }

  return total
}

pub fn (mut qt Quadtree) split() {
  if qt.nodes.len == 4 {
    return
  }

  next_level := qt.level + 1
  sub_width := qt.bounds.width / 2
  sub_height := qt.bounds.height / 2
  x := qt.bounds.x
  y := qt.bounds.y

  qt.nodes.insert(0, Quadtree{
    bounds: Bounds{
    x: x + sub_width
    y: y
    width: sub_width
    height: sub_height
    }
    max_objects: qt.max_objects
    max_levels: qt.max_levels
    level: next_level
    objects: []Bounds{}
    nodes: []Quadtree{cap: 4}
  })

  qt.nodes.insert(1, Quadtree{
    bounds: Bounds{
    x: x
    y: y
    width: sub_width
    height: sub_height
    }
    max_objects: qt.max_objects
    max_levels: qt.max_levels
    level: next_level
    objects: []Bounds{}
    nodes: []Quadtree{cap: 4}
  })

  qt.nodes.insert(2, Quadtree{
    bounds: Bounds{
    x: x
    y: y + sub_height
    width: sub_width
    height: sub_height
    }
    max_objects: qt.max_objects
    max_levels: qt.max_levels
    level: next_level
    objects: []Bounds{}
    nodes: []Quadtree{cap: 4}
  })

  qt.nodes.insert(3, Quadtree{
    bounds: Bounds{
    x: x + sub_width
    y: y + sub_height
    width: sub_width
    height: sub_height
    }
    max_objects: qt.max_objects
    max_levels: qt.max_levels
    level: next_level
    objects: []Bounds{}
    nodes: []Quadtree{cap: 4}
  })
}

fn (qt &Quadtree) get_index(rect Bounds) int {
  mut index := -1
  vertical_midpoint := qt.bounds.x + (qt.bounds.width /2)
  horizontal_midpoint := qt.bounds.y + (qt.bounds.height /2)

  top_quadrant := (rect.y < horizontal_midpoint) && (rect.y + rect.height < horizontal_midpoint)

  bottom_quadrant := (rect.y > horizontal_midpoint)

  if (rect.x < vertical_midpoint) && (rect.x+rect.width < vertical_midpoint) {

    if top_quadrant {
      index = 1
    } else if bottom_quadrant {
      index = 2
    }

  } else if rect.x > vertical_midpoint {

    if top_quadrant {
      index = 0
    } else if bottom_quadrant {
      index = 3
    }

  }

  return index
}


fn (mut qt Quadtree) qt_insert(rect Bounds) {

  qt.total++

  mut i := 0
  mut index := 0

  if qt.nodes.len > 0 == true {

    index = qt.get_index(rect)

    if index != -1 {
      qt.nodes[index].qt_insert(rect)
      return
    }
  }

  for i < qt.objects.len {
    qt.objects.insert(i, rect)
  }

  if (qt.objects.len > qt.max_objects) && (qt.level < qt.max_levels) {

    if qt.nodes.len > 0 == false {
      qt.split()
    }

    for i < qt.objects.len {
      index = qt.get_index(qt.objects[i])

      if index != -1 {
        splice := qt.objects[i]                                  
        qt.objects = qt.objects[..i+1]

        qt.nodes[index].qt_insert(splice)

      } else {
        i++
      }
    }
  }
}

fn (qt &Quadtree) retrieve(rect Bounds) []Bounds {

  index := qt.get_index(rect)

  mut return_objects := qt.objects.clone()

  if qt.nodes.len > 0 {
    if index != -1 {
      for elem in qt.nodes[index].retrieve(rect) {
        return_objects.insert(return_objects.len, elem)
      }
    } else {
      for i := 0; i < qt.nodes.len; i++ {
        for elem in qt.nodes[index].retrieve(rect) {
          return_objects.insert(return_objects.len, elem)
        }
      }
    }
  }

  return return_objects
}

fn (qt &Quadtree) retrieve_points(find Bounds) []Bounds {

  mut found_points := []Bounds{}
  mut potentials := qt.retrieve(find)
  for o := 0; o < potentials.len; o++ {
    mut xy_match := potentials[o].x == f64(find.x) && potentials[o].y == f64(find.y)
    if xy_match && potentials[o].is_point() {
      found_points << find
    }
  }

  return found_points

}

fn (qt &Quadtree) retrieve_intersections(find Bounds) []Bounds {

  mut found_intersections := []Bounds{}
  mut potentials := qt.retrieve(find)
  for o := 0; o < potentials.len; o++ {
    if potentials[o].intersects(find) {
      found_intersections << potentials[o]
    }
  }

  return found_intersections

}


fn(mut qt Quadtree) qt_clear() {

  qt.objects = []Bounds{}

  if qt.nodes.len-1 > 0 {
    for i := 0; i < qt.nodes.len; i++ {
      qt.nodes[i].qt_clear()
    }
  }

  qt.nodes = []Quadtree{}
  qt.total = 0

}

pub fn setup_quadtree(x f64, y f64, width f64, height f64) &Quadtree {

  return &Quadtree{
    bounds: Bounds{
      x: x
      y: y
      width: width,
      height: height,
    },
    max_objects: 4,
    max_levels: 8,
    level: 0,
    objects: []Bounds{}
    nodes: []Quadtree{}
  }

}

fn rand_min_max(min f64, max f64) f64 {
  mut val := min + (rand.f64() * (max - min))
  return val
}

pub fn test_qt_insert() {

  mut qt := setup_quadtree(0, 0, 640, 480)

  grid := 10.0
  gridh := qt.bounds.width / grid
  gridv := qt.bounds.height / grid
  mut random_object := Bounds{}
  num_objects := 10

  for i := 0; i < num_objects; i++ {

    x := rand_min_max(0, gridh) * grid
    y := rand_min_max(0, gridv) * grid

    random_object = Bounds{
      x: x
      y: y
      width: rand_min_max(1, 4) * grid
      height: rand_min_max(1, 4) * grid
    }

    index := qt.get_index(random_object)
    if index < -1 || index > 3 {
      println('The index should be -1 or between 0 and 3, got ${index}')
    }

    qt.qt_insert(random_object)

  }

  if qt.total != num_objects {
    println('Error: Should have totalled ${num_objects}, got ${qt.total}')
  } else {
    println('Success: Total objects in the Quadtree is ${qt.total} (as expected)')
  }

}