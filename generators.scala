object generators {

  val rng = scala.util.Random
  
  case class XY(screenRowAdr: String, column: Int, colorRamRowAdr: String)

  def main(args: Array[String]): Unit = {
    // copy and paste the resulting data into the asm source code
    println(genStarLayers)
  }

  def genStarLayers(): String =
    ";;; starfield layer 0\n" +
    genStarLayer() + "\n" +
    ";;; starfield layer 1\n" +
    genStarLayer() + "\n"
    // ";;; starfield layer 2\n" +
    // genStarLayer()

  def genStarLayer(): String = {
    val numStars = 13 // TODO 13?

    val stars = for (i <- 0 to numStars) yield { 
      val row = (rng.nextFloat * 23).toInt
      val screenRamRowAdr = Integer.toHexString(0x0400 + row*40)
      val colorRamRowAdr = Integer.toHexString(0xd800 + row*40)
      val column = (rng.nextFloat * 39).toInt
      XY(screenRamRowAdr, column, colorRamRowAdr)
    }

    stars.map(_.screenRowAdr)  .mkString("\t\t.word $", ", $", "\n") +
    stars.map(_.column)        .mkString("\t\t.byte ", ", ", "\n") +
    stars.map(_.colorRamRowAdr).mkString("\t\t.word $", ", $", "\n")
  }
}

