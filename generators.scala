object Gen {

  val rnd = util.Random
  
  case class XY(screenRowAdr: String, column: Int, colorRamRowAdr: String)

  def genStarLayers() {
	println(
	  ";;; starfield layer 0\n" +
	  genStarLayer() + "\n" +
	  ";;; starfield layer 1\n" +
	  genStarLayer() + "\n"
	  // ";;; starfield layer 2\n" +
	  // genStarLayer()
	)
  }

  def genStarLayer() = {
	val numStars = 13 // TODO 13?

    val stars = for (i <- 0 to numStars) yield { 
      val row = (rnd.nextFloat * 24).toInt
      val screenRamRowAdr = Integer.toHexString(0x0400 + row*40)
      val colorRamRowAdr = Integer.toHexString(0xd800 + row*40)
      val column = (rnd.nextFloat * 39).toInt
      XY(screenRamRowAdr, column, colorRamRowAdr)
    }

	stars.map(_.screenRowAdr)  .mkString("\t\t.word $", ",\t$", "\n") +
	stars.map(_.column)        .mkString("\t\t.byte ", ",\t", "\n") +
	stars.map(_.colorRamRowAdr).mkString("\t\t.word $", ",\t$", "\n")
  }
}

