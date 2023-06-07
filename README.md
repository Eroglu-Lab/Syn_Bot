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

After installing the required plugins, you can download the most recent release of this repository from the [releases page](https://github.com/Eroglu-Lab/Syn_Bot/releases). You can then simply launch the macro in FIJI by dragging and dropping the Syn_Bot.ijm file from the downloaded release into your FIJI window.
You will then see the following selection menu.

![Settings Menu Image](https://github.com/Eroglu-Lab/Syn_Bot/blob/main/syn_bot_menu_small.jpg)

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


