# Syn_Bot
## FIJI Syn_Bot Macro

This macro is being written for use by the Eroglu Lab at Duke University to count the number of colocalized synaptic puncta in fluorescence microscopy images. This technique was originally described [here](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3159596/).
Briefly, neuronal synapses contain specific proteins in the presynaptic terminal that differ from those found in the postsynaptic terminal. At a neuronal synapse these terminals are ~50nm apart and thus immunohistochemical staining of a protein from each compartment will give a colocalized signal due to the resolution limits of traditional fluorescence microscopy. 

The main feature of the macro is the analyzePuncta function which performs the following steps:
1) Opens an image and splits the channels
2) Reduces noise with the subtract background and gaussian blur filters
3) Thresholds the image for each channel to differentaite signal from background
4) Uses analyze particles to count the puncta and saves this information
5) Feeds the puncta from each channel into the Coloc_Calc plugin
6) The plugin determines the colocalizations and returns the position and area of each
7) A feedback image is produced and all data are saved

To use the macro one needs to first have an **up to date version** of [FIJI](https://fiji.sc/) installed and then install the Coloc_Calc plugin by moving the [Coloc_Calc.jar](https://github.com/savagedude3/Syn_Bot/blob/master/Coloc_Calc-2.1.2-SNAPSHOT.jar) file from this repository into the "plugins" folder in FIJI (right-click the application and open package contents). You'll also need the [Bio-Formats Importer](https://imagej.net/Bio-Formats) if it is not already installed. Restart FIJI after plugin installation.

The ilastik thresholding option requires installing the [ilastik software package](https://www.ilastik.org/download.html) and the [ilastik FIJI Plugins](https://github.com/ilastik/ilastik4ij).

After installing the required plugins simply launch the plugin in FIJI using Plugins>Macros>Run. Your file system will then come up where you should select the [Syn_Bot.ijm](https://github.com/savagedude3/Syn_Bot/blob/master/Syn_Bot.ijm) file. You will then see the following settings menu.

![Settings Menu Image](https://github.com/savagedude3/Syn_Bot/blob/master/dialog_image.png)

## Start-up wizard 
This option begins a guided process to determine the necessary parameters for the macro, similar to the description below

## Analysis Type
This section has two options: 2 Channel Colocalization (RG) and 3 Channel Colocalization (RGB). 2 Channel Colocalization is the original task of the Syn_Bot and will analyze the colocalizations between the red and green puncta of the input images. The 3 Channel Colocalization will run the same as 2 Channel Colocalization, but will then run a thirdPuncta function which will analyze the puncta of the blue channel and then send these puncta through the Coloc_Calc plugin along with the colocalized puncta found from the red and green channels to find the triple colocalized puncta.

This sections also has 3 numerical input boxes to add the minimum pixel values for each channel. These are used by the built-in FIJI Analyze Particles function to count the puncta for each channel, excluding those puncta with an area less than the entered value. This value requires some experimentation, but we've found 4 pixels for in vivo and 8 pixels to be a good starting point.

## Thresholding
This section has four options: Manual, Fixed Value, Percent Histogram, FIJI auto ilastik, and Pre-Thresholded. Manual requires the user to manually adjust the threshold for each channel of each image analyzed using the built-in FIJI Threshold function sliders. The Fixed Value option uses a single threshold value for each channel which is applied to all images analyzed. The Percent Histogram option uses the percentThreshold function of the macro which calculates a threshold value which will include the top n% of pixels based on their intensity. The FIJI auto option allows the user to use any of the thresholding methods found in the Image>Adjust>Auto Threshold menu of FIJI. The ilastik option allows the user to apply a pre-trained ilastik algorithm to threshold the image. Training should be performed ahead of time in ilastik and then the Syn_Bot will need access to the ilastik application and the ilastik project files (.ilp) trained for each channel. The Pre-Thresholded option allows the user to input merged, pre-thresholded images and skips the preprocessing and thresholding steps. 

This section also has 3 numerical input boxes to add the n% of pixels to be included in the threshold calculated by percentThreshold. We've found 2% to be a good starting value, but this will also require some experimentation. The percentThreshold function is used as a starting point for the manual thresholding mode as well.

## ROI Type
This section has four options: Whole Image, Auto Cell Body, Circle, and custom. The Whole Image option simply analyzes the entire input image and is used for most in vivo images. The Auto Cell Body option uses the autoCellBody function to try and find the center of a neuronal cell body for in vitro images using the red channel. This works by using a Gaussian Blur filter with a high sigma value (50) to blur the puncta in the red channel into one large blob. If the postsynaptic puncta are in the red channel, there is a high density of signal near the cell body and there is only one dense patch of signal in the image. Once this center value is found, a circular ROI is created around this point. The Circle option works in much the same way as the Auto Cell Body option except the user is asked to click on the center of the cell in each image and that point is used to generate the ROI. If either the Auto Cell Body and Circle options are selected, a second menu will appear asking for the radius to be used in generating the circular ROI. The final custom option requires the user to select their own ROI for each channel of each image and allows the use of any FIJI ROI type, including the free-hand selection tool. 

## Offset
The offset checkbox is a bit experimental and is our attempt at something like the cumulative thresholding method discussed in: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4464180/. This will offset the threshold values used by the macro using values entered in a subsequent menu if this option is selected. This may be helpful in finding the correct threshold values for different experiments.

## Noise Reduction
The noise reduction checkbox will apply the FIJI subtract background function using a rolling ball radius of 50 followed by a gaussian blur filter using a sigma value of 0.57 to remove noise from each channel of each image. 

## Brightness Adjustment
The brightness adjustment checkbox will adjust the brightness of each channel of each image so the 1% of the pixels are saturated. This can be helpful if variable brightness is preventing colocalization calculations but will also change the intensity values of the images and should be used with caution.


## Want to know how Syn_Bot works?
See the [HowItWorks.md](https://github.com/savagedude3/Syn_Bot/blob/master/HowItWorks.md).


