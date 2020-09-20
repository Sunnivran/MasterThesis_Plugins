/*
 * To the extent possible under law, the ImageJ developers have waived
 * all copyright and related or neighboring rights to this tutorial code.
 *
 * See the CC0 1.0 Universal license for details:
 *     http://creativecommons.org/publicdomain/zero/1.0/
 */

package pg.kask.pizak.imagej;

import ij.ImagePlus;
import ij.gui.ProgressBar;
import ij.io.FileSaver;
import ij.io.Opener;
import net.imagej.Dataset;
import net.imagej.ImageJ;
import net.imagej.ops.OpService;
import net.imglib2.RandomAccessibleInterval;
import net.imglib2.img.Img;
import net.imglib2.type.numeric.RealType;
import org.scijava.command.Command;
import org.scijava.plugin.Parameter;
import org.scijava.plugin.Plugin;
import org.scijava.ui.UIService;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import ij.gui.GenericDialog;
import fiji.util.gui.GenericDialogPlus;
import org.scijava.util.FileUtils;


@Plugin(type = Command.class, menuPath = "Plugins>Segmentation Service Caller")
public class SegmentationCaller<T extends RealType<T>> implements Command {
    //
    // Feel free to add more parameters here...
    //

    @Parameter
    private Dataset currentData;

    @Parameter
    private UIService uiService;

    @Parameter
    private OpService opService;

    private String getPathFromImage(ImagePlus image) {
        String path = "";

        String extension = FileUtils.getExtension(image.getFileInfo().fileName);
        // create temporary path to save image to
        try {
            path = Files.createTempFile("fiji_SSCplugin", extension).toString();
        } catch (IOException e) {
            e.printStackTrace();
        }
        System.out.println("Saving image to " + path);

        // save image
        FileSaver fs = new FileSaver(image);
        fs.saveAsRawStack(path);

        return path;
    }

    @Override
    public void run() {

        //0. Add progress bar to main gui
        ProgressBar progressBar = new ProgressBar(100,20);
        progressBar.show(0,5);

        //1. Create and show GUI
        GenericDialogPlus gui = new GenericDialogPlus("Segmentation Service Caller");
        gui.addImageChoice("Choose input image:", "");
        gui.addFileField("Output file:","");

        gui.addSlider("Slider param:", 0.0, 1.0, 0.5);
        gui.addStringField("Text box param:", "Text box param");
        gui.addCheckbox("Check box param:", false);
        String[] radioButtonOptions = {"FirstOption", "SecondOption",
                "ThirdOption"};
        gui.addRadioButtonGroup("Radio button param:", radioButtonOptions,
                3, 1, radioButtonOptions[0]);
        gui.showDialog();

        progressBar.show(1,5);

        //1.1. If User did not clicked 'OK', end
        if(!gui.wasOKed()) {
            progressBar.show(5, 5);
            return;
        }

        //2. Get parameters from GUI
        ImagePlus inputImage = gui.getNextImage();
        String inputPath = getPathFromImage(inputImage);
        String outputPath = gui.getNextString();

        double sliderValue = gui.getNextNumber();
        String textBoxValue = gui.getNextString();
        boolean checkBoxValue = gui.getNextBoolean();
        String radioButtonValue = gui.getNextRadioButton();
        String params = sliderValue + "|" +
            textBoxValue + "|" +
            checkBoxValue + "|" +
            radioButtonValue;

        Path resourceDir = Paths.get("src","main");
        String scriptPath = resourceDir.toString() + "/SegmentationRedirect.sh";

        System.out.println("Input: " + inputPath);
        System.out.println("Output: " + outputPath);
        System.out.println("Params: " + params);

        progressBar.show(2,5);

        try {
            String[] cmd = {"/bin/sh", scriptPath,
                    inputPath, outputPath, params};

            Process p = Runtime.getRuntime().exec(cmd);

            progressBar.show(3,5);

            BufferedReader in = new BufferedReader(
                    new InputStreamReader(p.getInputStream()));
            String bashScriptOutput = "";
            while (true) {
                bashScriptOutput = in.readLine();
                if(bashScriptOutput == null)
                    break;
                System.out.println((bashScriptOutput));
            }

            progressBar.show(4,5);
        } catch (IOException e) {
            e.printStackTrace();
        }

        //5. Show output file
        Opener opener = new Opener();
        opener.open(outputPath);

        progressBar.show(5,5);
    }

    /**
     * This main function serves for development purposes.
     * It allows you to run the plugin immediately out of
     * your integrated development environment (IDE).
     *
     * @param args whatever, it's ignored
     * @throws Exception
     */
    public static void main(final String... args) throws Exception {
        // create the ImageJ application context with all available services
        final ImageJ ij = new ImageJ();
        ij.ui().showUI();

        // ask the user for a file to open
        final File file = ij.ui().chooseFile(null, "open");

        if (file != null) {
            // load the dataset
            final Dataset dataset = ij.scifio().datasetIO().open(file.getPath());

            // show the image
            ij.ui().show(dataset);

            // invoke the plugin
            ij.command().run(SegmentationCaller.class, true);
        }
    }

}
