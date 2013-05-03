object Gen {
  
  def genStars() {
    val rnd = util.Random
	val numStars = 13
    print("\t\t.word ")
    for (i <- 0 to numStars) { 
      val row = (rnd.nextFloat * 24).toInt
      val rowAdr = Integer.toHexString(0x400 + row*40)
      print("$" + rowAdr)
    }
	print("\n")
    for (i <- 0 to numStars) { 
      val col = (rnd.nextFloat * 39).toInt
      println("\t\t.byte " + col)
    }
  }
}

