# Syn_Bot
## FIJI Syn_Bot Macro

This macro was developed by Cagla Eroglu's Lab at Duke University to count the number of colocalized synaptic puncta in fluorescence microscopy images. The macro and related experimental methods are thoroughly described in our paper [insert link to paper]().

Briefly, neuronal synapses contain specific proteins in the presynaptic terminal that differ from those found in the postsynaptic terminal. At a neuronal synapse these terminals are ~50nm apart and thus immunohistochemical staining of a protein from each compartment will give a colocalized signal due to the resolution limits of traditional fluorescence microscopy. 

The primary components of analyzing these sorts of images include: 
1) reduction of noise 
2) thresholding of each image channel 
3) counting of puncta in each channel
4) calculating which puncta colocalize with puncta in the other channel

## Installation

To use the macro one needs to first have an **up to date version** of [FIJI](https://fiji.sc/) installed and then install the ilastik4ij_Syn_Bot plugin by moving the [ilastik4ij_Syn_Bot.jar] file from this repository into the "plugins" folder in FIJI (right-click the application and open package contents on Mac). You'll also need the [Bio-Formats Importer](https://imagej.net/Bio-Formats) if it is not already installed. Restart FIJI after plugin installation.

The ilastik thresholding option requires installing the [ilastik software package](https://www.ilastik.org/download.html) and using it to train to ilastik project files (described in this [video](https://youtu.be/KY2lKaHMjcU)).

After installing the required plugins, you can download the most recent release of this repository from the [releases page](https://github.com/Eroglu-Lab/Syn_Bot/releases). 

## Preparing Your Images 

Before running SynBot, it is recommended to convert your images into the Tiff format, though
SynBot can run on a variety of file types, this is a frequent source of error. (See the extra_code
folder at https://github.com/Eroglu-Lab/Syn_Bot for example image type conversion macros).

Note: SynBot works best when images have unique names that contain only one "." character
which precedes the file extension (i.e. names like image_1.tif instead of image.1.tif).

Note: It is always best practice to run image analysis software on a copy of your images so
that the original images are preserved

Create a folder for your experiment with subfolders for experimental groups. Each experimental
group folder should contain only image files. Multiple experimental groups are not required, but
your files must follow the Experiment/Group/Image structure.

## Running SynBot
Once the prerequisites are properly installed, Click and drag the Syn_Bot.ijm file into FIJI to open it in the FIJI script editor. Next, click the run button on the bottom left corner of the script editor to run the macro. You will then see the following selection menu.

![Settings Menu Image](https://github.com/Eroglu-Lab/Syn_Bot/blob/main/syn_bot_menu_small.png)

## Channels 
Select the appropriate number of channels to be analyzed (2 or 3). Images will be converted to the RedGreenBlue (RGB) format and the Red and Green channels will be analyzed for 2-Channel Colocalization and the Red, Green, and Blue channels will be analyzed for 3-Channel Colocalization. If necessary, image channels can be changed to fit these colors using the Pick Channels option.

## Preprocessing
Select whether or not to use the noise reduction or brightness adjustment
preprocessing functions. Noise reduction is recommended for most in vivo imaging applications.
Brightness Adjustment is not recommended unless absolutely necessary since it alters the
intensity of the original images, but can be helpful if all images are uniformly dim.

## Thresholding 
Select the desired thresholding method from the provided options. This protocol
will focus on the manual thresholding option where each channel of each image is assigned a
threshold by the user.

## ROI Type
Select the desired region of interest (ROI) type from the provided options. Whole
Image should be selected unless there is a specific ROI within the image to focus analysis
around.

Within ROI Type, the user also selects minimum and maximum pixel values for each channel.
These are the bounds on the area (in pixel units) of the smallest and largest puncta to be
included in the analysis.

## Analysis Type
Select either the circular-approximation or pixel-overlap analysis modes. The
pixel-overlap method is recommended for most applications and uses the individual pixels of
each channel to determine colocalizations. The circular-approximation mode uses the area and
location of the puncta for each channel to approximate each puncta as a circle and then
determine if the circles from each channel are overlapping and is only recommended when
comparing to results obtained with previous algorithms that used circular-approximation (such
as Puncta Analyzer).

## Experiment Directory
Click the browse button and select the Experiment level folder that we set
up earlier. You must select the Experiment-level folder rather than the Group-level folder or image
files

Once the desired settings have been entered, click the OK button to begin running SynBot. 

The subsequent user inputs will depend on the initial parameters chosen in the selection menu. Here we will describe the manual thresholding case, but on-screen prompts and other tutorials describe other analysis modes. 

## Manual Thresholding
Once preprocessing has been completed, the first channel of the first image will appear. Adjust
the sliders in the Threshold box until the foreground pixels are kept while excluding most of the
background pixels. Typically only the lower threshold will be adjusted with the upper threshold
remaining at the maximum value of 255. Click OK once the desired threshold is chosen.

Next, the macro will display the green channel of the image. Threshold this image using the
Threshold sliders as you did in the previous step.

Repeat Manual Thresholding for each image in the data set.

## Data Outputs
Once thresholding all images is completed, a results file called Summary.csv will be displayed.
This file is automatically saved within the Experiment-level folder selected earlier and can be
closed.

Navigate to the Group-level folders within the Experiment-level folder selected earlier. These
Group folders will now each contain an Output folder which includes several useful outputs:
- A copy of the original image converted to RGB (i.e. image_1.tif)
- A copy of the original image with white overlays labeling each counted colocalization (i.e.
image_1_colocs.tif)
- The thresholded image for each channel (i.e. image_1_redThresholded_0.tiff)
- The full set of measurements of each punctum counted for each channel (i.e. image_1_redResults_0.csv)
These files should be reviewed to ensure the program is counting colocalizations as desired.

Returning to the Experiment-level folder shows the Summary.csv file which includes the
summary statistics for each image that serve as the primary outputs of the SynBot analysis
including:
- Puncta counts for each channel
- Colocalized puncta count
- Thresholds used
- Min Pixel values used

Note: SynBot analyses can be quickly replicated by using the Threshold from File
thresholding method and selecting the Summary.csv file from a previous run as the input
file. This will then rerun the analysis using the same thresholds, allowing the user to
optimize any of the other analysis parameters.





