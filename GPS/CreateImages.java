import com.googlecode.pngtastic.core.PngImage;
import com.googlecode.pngtastic.core.PngOptimizer;
import java.awt.*;
import java.awt.image.*;
import java.io.*;
import java.util.*;
import javax.imageio.*;
import javax.imageio.stream.*;

public class CreateImages {
  private static BufferedImage imageToBufferedImage(Image im) {
    BufferedImage bi = new BufferedImage
    (im.getWidth(null),im.getHeight(null),BufferedImage.TYPE_INT_RGB);
    Graphics bg = bi.getGraphics();
    bg.drawImage(im, 0, 0, null);
    bg.dispose();
    return bi;
  }
 
  static boolean createImages(String parkId, String[] images, String[] originalImages) {
    for (String imageName : images) {
      if (!imageName.endsWith(".jpg")) continue;
      boolean contains = false;
      for (String name : originalImages) {
        if (name.equals(imageName)) {
          contains = true;
          break;
        }
      }
      if (!contains) System.out.println("Missing original image of " + imageName + " (may be to be deleted)");
    }
    File tmpFile = new File("tmp.jpg");
    tmpFile.delete();
    boolean newImages = false;
    for (String imageName : originalImages) {
      if (!imageName.endsWith(".jpg")) continue;
      if (imageName.startsWith(parkId + " - icon_") || imageName.equals(parkId + " - background.jpg") || imageName.equals(parkId + " - logo.jpg")) continue;
      String imagePath = "../data/" + parkId + '/' + imageName;
      String originalImagePath = "bilder/" + parkId + '/' + imageName;
      BufferedImage img = null;
      FileImageOutputStream output = null;
      ImageWriter writer = null;
      try {
        img = ImageIO.read(new File(originalImagePath));
        img = imageToBufferedImage(img.getScaledInstance(200, 200, Image.SCALE_SMOOTH));
        Iterator iter = ImageIO.getImageWritersByFormatName("jpeg");
        writer = (ImageWriter)iter.next();
        ImageWriteParam iwp = writer.getDefaultWriteParam();
        iwp.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
        iwp.setCompressionQuality(0.93f);
        output = new FileImageOutputStream(tmpFile);
        writer.setOutput(output);
        IIOImage image = new IIOImage(img, null, null);
        writer.write(null, image, iwp);
      } catch (Exception e) {
        e.printStackTrace();
      } finally {
        if (writer != null) writer.dispose();
        if (output != null) try { output.close(); } catch (IOException ioe) {}
      }
      File f1 = new File(imagePath);
      if (f1.exists()) {
        long l1 = f1.length();
        long l2 = tmpFile.length();
        if (l2 < l1) {
          System.out.println("Size of image " + imageName + " (" + l1 + " bytes) can be reduced to " + l2 + " bytes");
          f1.delete();
          FileUtilities.move("tmp.jpg", imagePath);
          newImages = true;
        } else {
          tmpFile.delete();
        }
      } else {
        System.out.println("Image " + imageName + " created");
        FileUtilities.move("tmp.jpg", imagePath);
        newImages = true;
      }
    }
    return newImages;
  }

  public static void pngtasticOptimizer(String path, String[] fileNames) {
		long start = System.currentTimeMillis();
		PngOptimizer optimizer = new PngOptimizer(null);
		optimizer.setCompressor("zopfli");
    if (fileNames == null) {
      if (path.endsWith(".png")) {
        try {
          PngImage image = new PngImage(path);
          optimizer.optimize(image, path, Boolean.FALSE, null);
        } catch (IOException e) {
          e.printStackTrace();
        }
      }
    } else {
      for (String file : fileNames) {
        if (file.endsWith(".png")) {
          try {
            file = path + file;
            PngImage image = new PngImage(file);
            optimizer.optimize(image, file, Boolean.FALSE, null);
          } catch (IOException e) {
            e.printStackTrace();
          }
        }
      }
		}
		System.out.println(String.format("Processed %d files in %d milliseconds, saving %d bytes", optimizer.getStats().size(), System.currentTimeMillis() - start, optimizer.getTotalSavings()));
	}

  // java -cp GPS.jar CreateImages [<parkId>|<folder to compress png files>|<png file to compress>]
  public static void main(String[] args) {
    if (args.length != 1) {
      System.err.println("USAGE: [<park ID>|<folder to compress png files>|<png file to compress>]");
      System.err.println(" e.g. java -jar GPS.jar ep");
      return;
    }
    String parkId = args[0];
    File file = new File(parkId);
    if (file.exists() && file.isDirectory()) {
      if (!parkId.endsWith("/")) parkId += "/";
      pngtasticOptimizer(parkId, file.list());
    } else if (parkId.endsWith(".png") && file.exists()) {
      pngtasticOptimizer(parkId, null);
    } else {
      file = new File("../data/" + parkId);
      if (file.exists() && file.isDirectory()) {
        file = new File("../data");
        String[] images = file.list();
        file = new File("bilder/" + parkId);
        String[] originalImages = file.list();
        boolean newImages = false;
        if (file.exists()) newImages = createImages(parkId, images, originalImages);
        if (newImages) {
          file = new File("../data/" + parkId + "/maps");
          if (file.exists()) pngtasticOptimizer("../data/" + parkId + "/maps/", file.list());
        }
      } else {
        System.out.println("unknown folder");
      }
    }
  }
}
