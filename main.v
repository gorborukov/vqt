module main

import quadtree

fn main() {
  //split testing
  mut qt := quadtree.setup_quadtree(0,0,640,480)
  qt.split()

  for i := 0; i < qt.nodes.len; i++ {
    qt.nodes[i].split()
  }

  mut total := qt.total_nodes()
  if total != 20 {
    println('Expected 20 nodes but got ${total}')
  } else {
    println('Quadtree got ${total} nodes')
  }

  // insertion testing
  quadtree.test_qt_insert()
}




