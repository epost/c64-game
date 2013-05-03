object Gen {
  
  def genStars() {
    val rnd = util.Random
    for (i <- 0 to 10) { 
      val row = (rnd.nextFloat * 24).toInt
      val col = (rnd.nextFloat * 39).toInt
      val rowAdr = Integer.toHexString(0x400 + row*40)
      println (".word $" + rowAdr + "\n" +
               ".byte " + col)
    }
  }
}

