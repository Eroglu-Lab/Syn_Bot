# Syn_Bot
## FIJI Syn_Bot Macro

This macro was developed by Cagla Eroglu's Lab at Duke University to count the number of colocalized synaptic puncta in fluorescence microscopy images. The macro and related experimental methods are thoroughly described in our paper [insert link to paper]().

Briefly, neuronal synapses contain specific proteins in the presynaptic terminal that differ from those found in the postsynaptic terminal. At a neuronal synapse these terminals are ~50nm apart and thus immunohistochemical staining of a protein from each compartment will give a colocalized signal due to the resolution limits of traditional fluorescence microscopy. 

The primary components of analyzing these sorts of images include: 
1) reduction of noise 
2) thresholding of each image channel 
3) counting of puncta in each channel
4) calculating which puncta colocalize with puncta in the other channel


To use the macro one needs to first have an **up to date version** of [FIJI](https://fiji.sc/) installed and then install the ilastik4ij_Syn_Bot plugin by moving the [ilastik4ij_Syn_Bot.jar] file from this repository into the "plugins" folder in FIJI (right-click the application and open package contents on Mac). You'll also need the [Bio-Formats Importer](https://imagej.net/Bio-Formats) if it is not already installed. Restart FIJI after plugin installation.

The ilastik thresholding option requires installing the [ilastik software package](https://www.ilastik.org/download.html).

After installing the required plugins, you can download the most recent release of this repository from the [releases page](https://github.com/Eroglu-Lab/Syn_Bot/releases). You can then simply launch the macro in FIJI by dragging and dropping the Syn_Bot.ijm file from the downloaded release into your FIJI window.
You will then see the following settings menu.

![Settings Menu Image](https://github.com/savagedude3/Syn_Bot/blob/master/dialog_image.png)

## Start-up wizard
This option begins a guided process to determine the necessary parameters for the macro, similar to the description below.

## Analysis Type 
This option allows the user to select either a circle-based or pixel-based process for calculating colocalizations. These options are described for the 2-channel case below.

### Circle-based Colocalization Calculation

With this analysis mode selected, the coordinates and radius of each punctum for the channels to be analyzed are passed through the Syn_Bot_Helper java plugin (packaged within the ilastik4ij_Syn_Bot JAR file). A java plugin is used for this step because it can perform the necessary calculations much more efficiently than if they were done with ImageJ macro language. These values for each puncta in the first channel are then compared to each puncta in the second channel, calculating an area of colocalization using the geometry described by Robert Eisele https://www.xarg.org/2016/07/calculate-the-intersection-area-of-two-circles/. The basic idea of this method is to use the intersection points of the circles along with the center of each circle to define two triangles while also finding the areas of the sector of each circle between the two intersection points. Subtracting the area of each triangle from the area of its surrounding sector gives the half of the overlapping area contributed by that punctum. This can be done for both puncta to give the total area of the overlap. If this area is greater than 0, the coordinates and area of the overlap are stored and added to the colocalized puncta count. This method will work for any images with approximately circular puncta that can be any two sizes larger than the minimum pixel size used and do not have to have the same radius.

### Pixel-based Colocalization Calculation

Rather than approximating each punctum to a circle, this analysis mode uses the puncta found by Syn_Bot for each channel and compares them in a pixel-by-pixel fashion using the FIJI Image Calculator plugin’s AND function. This will create a new image where only those pixels that are part of a red punctum and a green punctum are marked. This new image can then be quantified by FIJI’s analyze particles plugin to get the same coordinate and area information collected by the circle-based method. The advantage of this method is that it does not require the puncta of interest to be circular and also runs much more quickly than the circle-based method, especially when applied to three channels.

## Channels
This section has two options: 2 Channel Colocalization (RG) and 3 Channel Colocalization (RGB). 2 Channel Colocalization is the original task of the Syn_Bot and will analyze the colocalizations between the red and green puncta of the input images. The 3 Channel Colocalization will preprocess the images (described below) the same as 2 Channel Colocalization, but will then either use a modified version of the circle-based method to calculate triple colocalizations or use an additional pixel-based step to calculate pixels that are part of both the red-green colocalizations and the blue channel.
This section also has 3 numerical input boxes to add the minimum pixel area values for each channel. These are used by the built-in FIJI Analyze Particles function to count the puncta for each channel, excluding those puncta with an area less than the entered value. This value requires some experimentation, but we've found 4 pixels for in vivo and 8 pixels for in vitro to be a good starting point for the imaging set up described here.

## Thresholding
Thresholding is the process of distinguishing the foreground (synaptic puncta) of an image from the background. Synapse colocalization images tend to have a decent amount of noise as well as variability of the intensity of puncta within and between images. For these reasons, discriminating between true puncta and background in this context is not trivial and has led us to include as many methods as possible options the Syn_Bot user can utilize to overcome this problem. 
This section has six options: Manual, Fixed Value, Percent Histogram, FIJI auto, ilastik and Pre-Thresholded. Manual requires the user to manually adjust the threshold for each channel of each image analyzed using the built-in FIJI Threshold function sliders. The Fixed Value option uses a single threshold intensity value for each channel which is applied to all images analyzed. The Percent Histogram option uses the percentThreshold function of the macro which calculates a threshold value which will include the top n% of pixels based on their intensity, with the n% supplied by the user in a subsequent pop-up window. The FIJI auto option allows the user to use any of the thresholding methods found in the Image>Adjust>Auto Threshold menu of FIJI. The ilastik option allows the user to apply pretrained ilastik projects to threshold each channel in their image by utilizing an altered version of the ilastik4ij plugin. The Pre-Thresholded option allows users to use images that have already been thresholded outside of this macro, allowing for the application of more sophisticated thresholding algorithms.

This section also has 3 numerical input boxes to add the n% of pixels to be included in the threshold calculated by percentThreshold. We've found 2% to be a good starting value, but this will require some experimentation as the staining between and within these experiments can be quite variable. The percentThreshold function is used as a starting point for the manual thresholding mode as well.

## ROI Type
This section has four options: Whole Image, Auto Cell Body, Circle, and custom. The Whole Image option simply analyzes the entire input image and is used for most in vivo images. The Auto Cell Body option uses the autoCellBody function to try and find the center of a neuronal cell body for in vitro images using the red channel. This works by using a Gaussian Blur filter with a high sigma value (50) to blur the puncta in the red channel into one large blob. If the postsynaptic puncta are in the red channel, there is a high density of signal near the cell body and there is only one dense patch of signal in the image. Once this center value is found, a circular ROI is created around this point. The Circle option works in much the same way as the Auto Cell Body option except the user is asked to click on the center of the cell in each image and that point is used to generate the ROI. If the Auto Cell Body function fails, it will switch the ROI method to the Circle option. If either the Auto Cell Body or Circle options are selected, a second menu will appear asking for the radius to be used in generating the circular ROI. The final custom option requires the user to select their own ROI for each channel of each image and allows the use of any FIJI ROI type, including the free-hand selection tool.

## Offset
The offset checkbox is a bit experimental and is our attempt at something like the cumulative thresholding method discussed in: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4464180/. This will offset the threshold values used by the macro using values entered in a subsequent menu if this option is selected. This may be helpful in finding the correct threshold values for different experiments. Since this effectively runs the macro multiple times for each image, it will increase the runtime proportionally to the number of offset values used.

## Noise Reduction
The noise reduction checkbox will apply the FIJI subtract background function using a rolling ball radius of 50 followed by a gaussian blur filter using a sigma value of 0.57 to remove noise from each channel of each image. Note that this option should not be selected if ilastik or Pre-Thresholded methods are used as these methods should accomplish noise processing outside of Syn_Bot.

## Brightness Adjustment
The brightness adjustment checkbox will adjust the brightness of each channel of each image so the n% of the pixels are saturated (with n being defined by the user in a subsequent pop-up window). This can be helpful if variable brightness is preventing colocalization calculations but will also change the intensity values of the images and should be used with caution.

## Threshold from File
Another helpful checkbox on the Syn_Bot menu is “Threshold From File”. This option overrides whatever thresholding method was selected and instead asks the user to supply a CSV file containing the desired thresholds for each channel of each image. These thresholds can be copied from the output of a previous run of Syn_Bot and allows for a more rapid replication of a previous analysis if any of the simpler threshold methods were used.

## Input Images
After the main Syn_Bot menu parameters are entered, a pop-up window will be displayed to ask the user to select the “Source Directory”. This should be a large folder for the given experiment that contains subfolders for subgroups of the experiment. These subfolders should contain the images to be analyzed. In vivo Z-stack images can be used in most original file types (.oir, .czi, etc.). As described earlier, we typically collapse 15 Z-stacks into 5 Z-projections by projecting every three z-stacks together. Syn_Bot will attempt to perform this type of Z-projection on any input image Z-stacks. If some other method is desired, this should be performed prior to using Syn_Bot and the resulting projections or single-stacks should be used as input. Images are converted to 8-bit RGB images if they are not already in this format. The Processed images will be saved into a “Z_projections” folder which will be a subfolder within each experimental subgroup folder. This Z_projections folder will also be the site for saving any intermediate files such as the coordinates of puncta and the feedback images described below.

## User Input
After inputting the starting parameters for the macro, there is no more user input required unless the manual thresholding and/or the circle or custom ROI methods are selected. If one of these options is selected, an “Action Required” pop-up will be displayed with instructions for whatever input is necessary. Manual thresholding requires the user to adjust the threshold level for each channel of each image. This should be adjusted such that the foreground pixels are included in red and background pixels are excluded and remain black. The circle ROI requires the user to select the center of the cell body in the image to be analyzed. The custom ROI requires the user to select whichever ROI they would like to use for each image using any of the FIJI ROI selection tools.

## Feedback
The macro creates and saves a feedback image for each image that is analyzed within the Z_projections folder using the name of the image with “_colocs” appended to the end. This image shows the original input image with white circular overlays at the center position of each recorded colocalization. New users should check these images after running the macro and adjust their parameters (especially thresholding parameters) if they see too few or too many calculated colocalizations. 
