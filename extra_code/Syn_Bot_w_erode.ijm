/*  Syn_Bot
 *  Justin Savage
 *  1/10/23
 *  
 *  Depends on ilastik4ij_Syn_Bot plugin
 *  
 *  This macro is designed to analyze fluorescence microscopy images
 *  to determine the number of colocalizations between pre and postsynaptic
 *  markers which represent a structural synapse. 
 *  
 *  The macro is written to receive a folder containing subfolders for several
 *  imaging pairs with confocal images including 15 z stacks. Which are then 
 *  z-projected to create 5 projections of 3 images each. This projection 
 *  is skipped if the input images are not z-stacks. The macro also requires
 *  RGB images and will attempt to convert the images if they are not in this 
 *  format. 
 *  
 *  The main functionality of the macro is then run in the analyze puncta
 *  function which splits the image channels, closes the blue channel, 
 *  and does the following for the red and then green channel: 
 *  subtracts background and applies a gaussian filter to reduce 
 *  noise, selects an ROI if applicble, thresholds
 *  the image using a percentage of the histogram of pixel intensity such 
 *  that the value entered represents the percentage of pixels with the 
 *  greatest intensity that are included in the thresholded image. The 
 *  macro then uses the analyze particles function to count the number of 
 *  puncta for the channel. Once the puncta for each channel are counted,
 *  the macro uses the area of the puncta to calculate their radius and
 *  then the coordinates and radius of each puncta are fed into the Coloc_Calc
 *  plugin which uses the radius and coordinates of each puncta to determine 
 *  the number of colocalized puncta, which is displayed as a resuts table 
 *  that the macro then saves.
 *  
 *  The macro outputs csv files for the statistics of each puncta from
 *  the red and green channels, statistics for each colocalized puncta, 
 *  a feedback image in which each colocalized puncta is marked with an
 *  overlayed white dot and a zip file of the ROI used if applicable. 
 * 
 */
//Sets the measurements that will be used by analyze particles
//The order is important for accessing them later, but only the area
//and coordinates are used
run("Set Measurements...", "area mean standard centroid center bounding integrated display redirect=None decimal=3");

//Creates a dialog window for the user to input relevant parameters
Dialog.create("Syn Bot");
yesOrNo = newArray("yes", "no");
Dialog.addRadioButtonGroup("Do you want to use the start-up wizard? \n     If yes, click yes and then click Ok, ignoring the other parameters for now.", yesOrNo, 1, 2, "no");
analysisList = newArray("Circle-based", "Pixel-based");
channelList = newArray("2 Channel Colocalization (RG)", "3 Channel Colocalization (RGB)");
threshTypes = newArray("Manual", "Fixed Value", "Percent Histogram", "FIJI auto","ilastik", "Pre-Thresholded");
roiList = newArray("Whole Image", "Auto Cell Body", "Circle","Cell Territory" , "custom");
checkboxList = newArray("Offset?", "Noise Reduction?", "Brightness Adjustment?", "Threshold from File?", "90 degree control?", "Scramble Control?", "Pick Channels?");
Dialog.addRadioButtonGroup("Analysis Type", analysisList, 1, 2, "Circle-based");
Dialog.addRadioButtonGroup("Channels", channelList, 1, 2, "2 Channel Colocalization (RG)");
Dialog.addNumber("Red Min Pixel Size", 4);
Dialog.addToSameRow();
Dialog.addString("Red Max Pixel Size", "Infinity");
Dialog.addNumber("Green Min Pixel Size", 4);
Dialog.addToSameRow();
Dialog.addString("Green Max Pixel Size", "Infinity");
Dialog.addNumber("Blue Min Pixel Size", 4);
Dialog.addToSameRow();
Dialog.addString("Blue Max Pixel Size", "Infinity");
Dialog.addRadioButtonGroup("Thresholding", threshTypes, 2, 3, "Percent Histogram");
Dialog.addNumber("Red channel histogram percentage:", 2.5);
Dialog.addNumber("Green channel histogram percentage:", 2.0);
Dialog.addNumber("Blue channel histogram percentage:", 2.0);
Dialog.addRadioButtonGroup("ROI Type", roiList, 1, 5, "Whole Image");
Dialog.addCheckboxGroup(3, 3, checkboxList, newArray(false, false, false, false, false, false, false));
Dialog.addHelp("https://github.com/Eroglu-Lab/Syn_Bot");
Dialog.show();

wizardString = Dialog.getRadioButton();
analysisType = Dialog.getRadioButton();
channelType = Dialog.getRadioButton();
redMinPixel = Dialog.getNumber();
redMaxString = Dialog.getString();
greenMinPixel = Dialog.getNumber();
greenMaxString = Dialog.getString();
blueMinPixel = Dialog.getNumber();
blueMaxString = Dialog.getString();
threshType = Dialog.getRadioButton();
redHisto = Dialog.getNumber();
greenHisto = Dialog.getNumber();
blueHisto = Dialog.getNumber();
roiType = Dialog.getRadioButton();
offsetBool = Dialog.getCheckbox();
noiseBool = Dialog.getCheckbox();
brightBool = Dialog.getCheckbox();
fromFileBool = Dialog.getCheckbox();
rotateControlBool = Dialog.getCheckbox();
scrmbleControlBool = Dialog.getCheckbox();
pickChannelsBool = Dialog.getCheckbox();
print("pickChannelsBool = " + pickChannelsBool);


if(wizardString == "yes"){
	Dialog.create("Welcome");
	Dialog.addMessage("Welcome to the Syn_Bot Macro. \n This macro uses ImageJ to calculate colocalizations between pre and postynaptic puncta in fluorescence microscopy images.");
	Dialog.addMessage("The input to this macro is a big folder for your experiment that contains smallerfolders for each experimental group. \n The smaller folders for each experimental group contain microscope images to be analyzed. \n The macro will try to open, convert to RGB and ZProject these images \n (if any of these steps fail, preprocessing may be required.)");
	Dialog.addMessage("Prepare a folder using the Experiment/Experimental_Group/Images format and then click OK and select the prepared Experiment folder");
	Dialog.show();
	//Asks user for source directory (folder containing subfolder pairs)
	print("Choose Source Directory");
	dirSource  = getDirectory("Choose Source Directory ");
	listSource = getFileList(dirSource);

	listOffset = newArray(1);
		//for each pair m
		for(m = 0; m < listSource.length; m++){    
			currentFile = listSource[m];
			if ( indexOf(currentFile, ".") > -1){
	
				exit("Your input file either doesn't follow the required Experiment/Group/Image file structure or contains a '.' or duplicate file name");
		}
		//opens the first image and checks if it is already processed or not
		firstImages = getFileList(dirSource + currentFile);
		firstImage = firstImages[0];
		zProjectBool = false;
		rgbBool = false;
		rgbBool = checkRGB(dirSource + currentFile + firstImage);
		zProjectBool = checkZStack(dirSource + currentFile + firstImage);
		
			//creates a subfolder for eah pair that will store the Z-projected, RGB
		//images and eventually all of the macro outputs
		dirOut = dirSource + currentFile +"Output"+File.separator;
		File.makeDirectory(dirOut);
		
		if (pickChannelsBool == true){
			dirCorrected = dirSource + currentFile + "Corrected" + File.separator;
			File.makeDirectory(dirCorrected);
			print("making corrected directory");
			
			//uses correctChannels to change channels if pickChannels is selected
			correctChannels(dirSource + currentFile, dirCorrected, channelsList);
		
			if (zProjectBool == true){
				//uses the projectPair function to Z-project images if necessary
				projectPair(dirCorrected, dirOut);
				}
			if (zProjectBool == false){
				//uses the processCellImages function to convert in vitro images
				//to RGB
				//print("dirSource + currentFile " + dirSource + currentFile);
				//print("dirOut " + dirOut);
				processCellImages(dirCorrected, dirOut);
				}
		}
		if (pickChannelsBool == false){
			if (zProjectBool == true){
				//uses the projectPair function to Z-project images if necessary
				projectPair(dirSource + currentFile, dirOut);
				}
			if (zProjectBool == false){
				//uses the processCellImages function to convert in vitro images
				//to RGB
				//print("dirSource + currentFile " + dirSource + currentFile);
				//print("dirOut " + dirOut);
				processCellImages(dirSource + currentFile, dirOut);
				}
		}
		
			
		//list of processed images in dirOut
		listZ = getFileList(dirOut);
		//for each image in dirOut
		for(i = 0; i < 1; i++){
			currentImage = listZ[i];
			//for each threshold offset in listOffset
			//the main analyzePuncta function is applied to each image
			print("dirOut is " + dirOut);
			print("dirOut + currentImage is " + dirOut + currentImage);

			//This is where the wizard should run to get the parameters
			dir1 = dirOut + currentImage;
			setBatchMode(false);
			run("Bio-Formats Importer", "open=["+dir1+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
			titleArray = split(dir1, "/");
			title = titleArray[titleArray.length-1];
			
			print("indexOf " + indexOf(title, "Output"));
			
			titleTemp = title;
				
			if (indexOf(title, "Output") >= 0){
				z = indexOf(title, "Output");
				print("z is " + z);
				titleTemp = substring(title, z + 7, lengthOf(title));
				title = titleTemp;
			}


			run("RGB Color");
			
			close(title);
			selectWindow(title + " (RGB)");
			rename(title);
				
			print("title is " + title);
			run("Select All");
			getPixelSize(unit, pixelWidth, pixelHeight);
				 
			run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
			
			run("Split Channels");

			//close blue
			close(title + " (blue)");

			selectWindow(title + " (red)");
			splitName = split(titleTemp, ".");
			print("splitName is " + splitName[0]);
			run("Select All");

			run("Duplicate...", "title=noise_reduced");

			selectWindow("noise_reduced");
			run("Subtract Background...", "rolling=50");
			run("Gaussian Blur...", "sigma=0.57");

			Dialog.create("Red Channel Puncta");
			Dialog.addMessage("Displayed is the Red Channel of your first image. \n The first choice for the macro is whether this image needs the built in denoising features. \n The displayed image named noise_reduced has used our internal subtract background and gaussian blur. \n If this image doesn't look good, either use the raw image or complete your own denoising prior to using this macro. \n If you're using ilastik or other machine learning based thresholding algorithms, you should not use built-in denoising.");
			items = newArray("yes", "no");
			Dialog.addRadioButtonGroup("Would you like to use built-in denoising?", items, 1, 2, "yes");
			Dialog.show();
			noiseString = Dialog.getRadioButton();
			close("noise_reduced");
			selectWindow(title + " (red)");
			if(noiseString == "yes"){
				run("Subtract Background...", "rolling=50");
				run("Gaussian Blur...", "sigma=0.57");
			}

			run("Threshold...");

			Dialog.create("Red Channel Puncta II");
			Dialog.addMessage("The next parameter to determine is the threshold for the image. \n This is a pixel intensity value that separates pixels darker than that value (background) \n from pixels brighter than this value (foreground). \n There are 6 ways to threshold images for this macro. \n \n 1. Manual mode which allows manual thresholding for each image \n 2. Fixed value which uses a single threshold value for each image \n 3. Percent Threshold which uses a custom algorithm to apply a threshold keeping the top n% of pixels in the image \n 4. FIJI auto which uses any of the built-in automatic thresholding methods in FIJI \n 5. ilastik which uses the machine learning application ilastik to threshold images \n 6. Pre-Thresholded which allows images to be thresholded outside of Syn_Bot \n Adjust the threshold of the displayed image until you feel it correctly captures the desired puncta. \n Note either the threshold value or percent if you plan to use methods 2 or 3 \n You can try the automated FIJI methods using Image>Adjust>AutoThreshold and should note the name of the method that works best \n ilastik or Pre-Thresholded methods must be prepared outside of Syn_Bot (see ilastik.org) \n \n Click Ok to begin adjusting the threshold");
			Dialog.show();

			waitForUser("Adjust the threshold of the displayed image until you feel it correctly captures the desired puncta. \n Note either the threshold value or percent if you plan to use methods 2 or 3 \n You can try the automated FIJI methods using Image>Adjust>AutoThreshold \n and should note the name of the method that works best \n \n Click Ok when done");

			selectWindow(title + " (green)");
			if(noiseString == "yes"){
				run("Subtract Background...", "rolling=50");
				run("Gaussian Blur...", "sigma=0.57");
			}

			run("Threshold...");

			Dialog.create("Green Channel Puncta");
			Dialog.addMessage("The Green Channel is now displayed. \n The macro uses the same mode (Manual, Fixed Value, \n Percent Histogram, FIJI auto, ilastik or Pre-Thresholded) \n for each channel but different parameters can be used. \n \n Click Ok to begin adjusting the threshold");
			Dialog.show();

			waitForUser("Adjust the threshold of the displayed image until you feel it correctly captures the desired puncta. \n Note either the threshold value or percent if you plan to use methods 2 or 3 \n You can try the automated FIJI methods using Image>Adjust>AutoThreshold \n and should note the name of the method that works best \n \n Click Ok when done");

			waitForUser("There are only a few other settings necessary for the macro. \n \n 1. Analysis Type: Syn_Bot can calculate colocalizations either by approximating each punctum to a circle \n and then comparing the circles from each channel \n or by directly comparing the pixels in each channel to see which are part of puncta in each channel. \n 2. Channels: Syn_Bot can analyze either 2 (Red and Green) or 3 (Red, Green and Blue) channels. \n Since Syn_Bot analyzes the images in the RGB, images acquired in other color channels should be \n changed to these using the Lookup Tables in FIJI \n 3. Min Pixel Size: This denotes the smallest particle you wish to be counted \n as a true punctum. Examine your image and note the pixel size given when drawing an ROI \n around a typical punctum \n 4. ROI Type: Whole Image is used most often, but a circular ROI around a cell body or \n custom ROI around certain structures are also available. \n For further help and information see https://github.com/Eroglu-Lab/Syn_Bot \n \n Click Ok to begin the macro.");
			close("*");
			print("dirOut is: " + dirOut);
			listZ = getFileList(dirOut);
			for (i =0; i < listZ.length; i++){
				currentImage = listZ[i];
				File.delete(dirOut + currentImage);
				//print("deleting " + currentImage);
			}
			File.delete(dirOut);
			wizardString = "no";
		}
	}
	
	//Creates a dialog window for the user to input relevant parameters
	Dialog.create("Syn Bot Wizard Complete");
	Dialog.addMessage("Please close this window and reopen SynBot to continue");
	Dialog.show();
	exit();
}


//sets roi Radius
if(roiType == "Auto Cell Body" || roiType == "Circle"){
	Dialog.create("ROI Dimensions");
	Dialog.addNumber("ROI Radius", 301);
	Dialog.show();
	roiR = Dialog.getNumber();
}

//sets square ROI width
if(roiType == "Cell Territory"){
	Dialog.create("ROI Dimensions");
	Dialog.addNumber("ROI Width", 50);
	Dialog.show();
	roiWidth = Dialog.getNumber();
}

//sets offset
//each offset value will be added to the threshold prior to running 
//analyze particles 
if (offsetBool == true){
Dialog.create("Offset Settings");
Dialog.addMessage("Type a comma separated list in the box below with the offsets you would like to use \n ex. -4,-2,0,2,4");
Dialog.addString("Offset Array", "");
Dialog.show();
listOffset = Dialog.getString();
print(listOffset);
listOffset = split(listOffset, ",");
}
if (offsetBool == false){
	listOffset = newArray(1);
}

//Change threshType if fromFile is selected
if (fromFileBool == true){
	threshType = "fromFile";
	print("Choose Threshold File");
	threshFile = File.openDialog("Choose Threshold File");
	Table.open(threshFile);
	realHeadings = split(Table.headings, "	");
	//print("first heading is: " + realHeadings[0]);
	//print(realHeadings[0].matches("﻿Lower Red Threshold"));
	for (i = 0; i < realHeadings.length; i++) {
		//print("heading " + i + " is: " + realHeadings[i]);
		if (realHeadings[i].contains("Lower Red Threshold")){
			redLowHeading = realHeadings[i];
		}
		if (realHeadings[i].contains("Upper Red Threshold")){
			redHighHeading = realHeadings[i];
		}
		if (realHeadings[i].contains("Lower Green Threshold")){
			greenLowHeading = realHeadings[i];
		}
		if (realHeadings[i].contains("Upper Green Threshold")){
			greenHighHeading = realHeadings[i];
		}
	}
	redLowArray = Table.getColumn(redLowHeading);
	redUpArray = Table.getColumn(redHighHeading);
	greenLowArray = Table.getColumn(greenLowHeading);
	greenUpArray = Table.getColumn(greenHighHeading);
	tableName = getInfo("window.title");
	close(tableName);
}


if (threshType == "Fixed Value"){
	Dialog.create("Fixed Threshold Value");
	Dialog.addNumber("Lower Red Threshold Value", 70);
	Dialog.addNumber("Lower Green Threshold Value", 70);
	Dialog.addNumber("Lower Blue Threshold Value", 70);
	Dialog.show();
	setRedT = Dialog.getNumber();
	setGreenT = Dialog.getNumber();
	setBlueT = Dialog.getNumber();
}


if (threshType == "FIJI auto"){
	Dialog.create("FIJI auto Threshold");
	Dialog.addString("Red Threshold Method", "Default dark");
	Dialog.addString("Green Threshold Method", "Default dark");
	Dialog.addString("Blue Threshold Method", "Default dark");
	Dialog.addNumber("Red Auto Factor", 1);
	Dialog.addNumber("Green Auto Factor", 1);
	Dialog.addNumber("Blue Auto Factor", 1);
	Dialog.addNumber("Red Auto Constant", 0);
	Dialog.addNumber("Green Auto Constant", 0);
	Dialog.addNumber("Blue Auto Constant", 0);
	Dialog.show();
	redTMethod = Dialog.getString();
	greenTMethod = Dialog.getString();
	blueTMethod = Dialog.getString();
	redAutoFactor = Dialog.getNumber();
	greenAutoFactor = Dialog.getNumber();
	blueAutoFactor = Dialog.getNumber();
	redAutoConstant = Dialog.getNumber();
	greenAutoConstant = Dialog.getNumber();
	blueAutoConstant = Dialog.getNumber();
}

ilastikDir = "";
ilpRedDir = "";
ilpGreenDir = "";

if(threshType == "ilastik"){
	//The way Mac and Windows package the ilastik application is different
	//Mac considers the application a directory but Windows requires you
	//to select the Application file within the larger ilastik
	//directory.
	//Unsure how this feature will run on other operating systems
	if(indexOf(getInfo("os.name"), "Windows") >= 0){
		print("Windows Detected");
		print("Choose ilastik location");
		print("Make sure this is the application file and not just the folder \n it is contained in. The file path should be something like: \n C:\\Program Files\\ilastik-1.3.3post3\\ilastik.exe");
		
	}
	else if(indexOf(getInfo("os.name"), "Mac") >= 0){
		print("Mac Detected");
		print("Choose ilastik location");
		print("Select ilastik in your applications folder.\n The file path should be something like: \n /Applications/ilastik-1.4.0b-OSX.app/");
		
	}
	else{
		print("Unknown OS");
		print("Choose ilastik location");
		
	}
	//TODO: remove ilastik erode
	//Erode ilastik didn't seem to work well
	//Dialog.create("Do you want to erode the ilastik thresholded image?");
	//Dialog.addChoice("erode?", newArray("yes","no"));
	//Dialog.show();
	//erodeChoice = Dialog.getChoice();
	//print("erodeChoice: " + erodeChoice);
	
	run("Syn_Bot_Dialog");
	ilastikDir = getResultString("paths", 0);
	ilpRedDir = getResultString("paths", 1);
	ilpGreenDir = getResultString("paths", 2);
	run("Clear Results");
	close("Results");
	//print(ilastikPath);
	//print(ilpRedDir);
	//print(ilpGreenDir);
	run("Configure ilastik for Syn_Bot", "executablefile=["+ilastikDir+"] numthreads=-1 maxrammb=4096");
}

if (brightBool == true) {
	Dialog.create("Brightness Adjustment");
	Dialog.addNumber("Enter Desired Percent Saturated Pixels", 1);
	Dialog.show();
	brightPercent = Dialog.getNumber();
}

ilpBlueDir = "";
if (threshType == "ilastik" && channelType == "3 Channel Colocalization (RGB)"){
	ilpBlueDir = getDirectory("Choose ilp blue location");
}

//Ask for if cell terriotory roi should be in the center or 
//off center
var territoryMode = "";
temp1 = false;

if (roiType == "Cell Territory"){
	Dialog.create("Cell Territory Mode");
	autoTerrList = newArray("Center", "Offset", "Whole Territory");
	Dialog.addRadioButtonGroup("Place ROI in center of territory, offset, or use whole territory?",
	autoTerrList, 1, 1, "Whole Territory");
	//Dialog.addChoice("Place ROI in center of territory or offset?", autoTerrList);
	Dialog.show();
	territoryMode = Dialog.getRadioButton();
}

if (temp1 == true) {
	offCenterBool = true;
}

//The following is the main chunk of the macro, which calls several
//helper functions that are defined below it

//Asks user for source directory (folder containing subfolder pairs)
print("Choose Source Directory");
dirSource  = getDirectory("Choose Source Directory ");
listSource = getFileList(dirSource);

startTime = getTime();

//arrays to store values for the summary ouput
var imageList = newArray(10000);
var redList = newArray(10000);
var greenList = newArray(10000);
var colocList = newArray(10000);
var offsetUsed = newArray(10000);
var lowerRedT = newArray(10000);
var upperRedT = newArray(10000);
var lowerGreenT = newArray(10000);
var upperGreenT = newArray(10000);
var imageScale = newArray(10000);
var imageUnit = newArray(10000);
var iterator = 0;

//extras for blue channel
var blueList = newArray(10000);
var lowerBlueT = newArray(10000);
var upperBlueT = newArray(10000);



if(threshType == "fromFile"){
	lowerRedT = redLowArray;
	upperRedT = redUpArray;
	lowerGreenT = greenLowArray;
	upperGreenT = greenUpArray;
}

//for each pair m
for(m = 0; m < listSource.length; m++){    
	currentFile = listSource[m];
	if ( indexOf(currentFile, ".") > -1){
		exit("Your input file either doesn't follow the required Experiment/Group/Image file structure or contains a '.' or duplicate file name");
	}
	//opens the first image and checks if it is already processed or not
	firstImages = getFileList(dirSource + currentFile);
	firstImage = firstImages[0];
	zProjectBool = false;
	rgbBool = false;
	rgbBool = checkRGB(dirSource + currentFile + firstImage);
	zProjectBool = checkZStack(dirSource + currentFile + firstImage);
	//get channels to use from user if pick channels is selected
	if (pickChannelsBool == true){
		channelsList = pickChannels(dirSource + currentFile + firstImage);
	}

	//creates a subfolder for each pair that will store the Z-projected, RGB
	//images and eventually all of the macro outputs
	dirOut = dirSource + currentFile +"Output"+File.separator;
	File.makeDirectory(dirOut);

	if (pickChannelsBool == true){
		dirCorrected = dirSource + currentFile + "Corrected" + File.separator;
		File.makeDirectory(dirCorrected);
		print("making corrected directory");
			
		//uses correctChannels to change channels if pickChannels is selected
		correctChannels(dirSource + currentFile, dirCorrected, channelsList);
	
		if (zProjectBool == true){
			//uses the projectPair function to Z-project images if necessary
			projectPair(dirCorrected, dirOut);
		}
		if (zProjectBool == false){
			//uses the processCellImages function to convert in vitro images
			//to RGB
			//print("dirSource + currentFile " + dirSource + currentFile);
			//print("dirOut " + dirOut);
			processCellImages(dirCorrected, dirOut);
		}
	}
	if (pickChannelsBool == false){
		if (zProjectBool == true){
			//uses the projectPair function to Z-project images if necessary
			projectPair(dirSource + currentFile, dirOut);
		}
		if (zProjectBool == false){
			//uses the processCellImages function to convert in vitro images
			//to RGB
			//print("dirSource + currentFile " + dirSource + currentFile);
			//print("dirOut " + dirOut);
			processCellImages(dirSource + currentFile, dirOut);
		}
	}

	//list of processed images in z_projects
	listZ = getFileList(dirOut);
	//for each image in dirOut
	for(i = 0; i < listZ.length; i++){
		currentImage = listZ[i];
		//for each threshold offset in listOffset
		for(j = 0; j < listOffset.length; j++){
	
			k = j + (listOffset.length) * i;
			currentOffset = listOffset[j];
			//the main analyzePuncta function is applied to each image
			print("dirOut is " + dirOut);
			print("dirOut + currentImage is " + dirOut + currentImage);
			//analyzePuncta(dirOut + currentImage, dirOut, currentOffset, redMinPixel, greenMinPixel, blueMinPixel, roiType, imageList, redList, greenList, blueList, colocList, offsetUsed, lowerRedT, upperRedT, lowerGreenT, upperGreenT, lowerBlueT, upperBlueT, iterator, imageScale, imageUnit, ilpRedDir, ilpGreenDir, ilpBlueDir);
			analyzePuncta(dirOut + currentImage, dirOut, currentOffset, redMinPixel, greenMinPixel, blueMinPixel, roiType, ilpRedDir, ilpGreenDir, ilpBlueDir);

			
			//iterator is an iterator used to save the summary values
			//to the correct location
			iterator = iterator + 1;	
		}
	}
}


//Removes empty indices from arrays
imageList = Array.trim(imageList, iterator);
redList = Array.trim(redList, iterator);
greenList = Array.trim(greenList, iterator);
colocList = Array.trim(colocList, iterator);
offsetUsed = Array.trim(offsetUsed, iterator);
lowerRedT = Array.trim(lowerRedT, iterator);
upperRedT = Array.trim(upperRedT, iterator);
lowerGreenT = Array.trim(lowerGreenT, iterator);
upperGreenT = Array.trim(upperGreenT, iterator);
imageScale = Array.trim(imageScale, iterator);
imageUnit = Array.trim(imageUnit, iterator);

if (channelType == "3 Channel Colocalization (RGB)"){
	blueList = Array.trim(blueList, iterator);
	lowerBlueT = Array.trim(lowerBlueT, iterator);
	upperBlueT = Array.trim(upperBlueT, iterator);
}
	
redMinArray = newArray(iterator);
greenMinArray = newArray(iterator);
blueMinArray = newArray(iterator);
	
for(i = 0; i < iterator; i++){
	redMinArray[i] = redMinPixel;
	greenMinArray[i] = greenMinPixel;
	blueMinArray[i] = blueMinPixel;
}
	
Table.create("Summary");
Table.setColumn("Image", imageList);
Table.setColumn("Red Puncta Count", redList);
Table.setColumn("Green Puncta Count", greenList);
if (channelType == "3 Channel Colocalization (RGB)"){
	Table.setColumn("Blue Puncta Count", blueList);
}
Table.setColumn("Colocalized Puncta Count", colocList);
Table.setColumn("Offset Used", offsetUsed);
Table.setColumn("Lower Red Threshold", lowerRedT);
Table.setColumn("Upper Red Threshold", upperRedT);
Table.setColumn("Lower Green Threshold", lowerGreenT);
Table.setColumn("Upper Green Threshold", upperGreenT);
if (channelType == "3 Channel Colocalization (RGB)"){
	Table.setColumn("Lower Blue Threshold", lowerBlueT);
	Table.setColumn("Upper Blue Threshold", upperBlueT);
}
Table.setColumn("Red Min Pixel", redMinArray);
Table.setColumn("Green Min Pixel", greenMinArray);
if (channelType == "3 Channel Colocalization (RGB)"){
	Table.setColumn("Blue Min Pixel", blueMinArray);
}
Table.setColumn("Scale", imageScale);
Table.setColumn("Unit", imageUnit);
	
Table.save(dirSource + "Summary.csv");

print("done");
endTime = getTime();
print(((endTime - startTime)/1000.0) + " seconds");


//dir1 is the image to be analyzed
//dir2 is the folder to save files into
//currentOffset is used to offset the autoThreshold 
//value to be used
//minPixel is the min pixel sized used for Analyze Particles
//roiType is the roi type to be used for Analyze Particles
//the rest of the parameters allow analyzePuncta to access the summary 
//ouput arrays
			
// function analyzePuncta(dir1, dir2, currentOffset, redMinPixel, greenMinPixel, blueMinPixel, roiType,imageList, redList, greenList, blueList, colocList, offsetUsed, lowerRedT, upperRedT, lowerGreenT, upperGreenT, lowerBlueT, upperBlueT, iterator, imageScale, imageUnit , ilpRedDir, ilpGreenDir, ilpBlueDir){
function analyzePuncta(dir1, dir2, currentOffset, redMinPixel, greenMinPixel, blueMinPixel, roiType, ilpRedDir, ilpGreenDir, ilpBlueDir){
	//batch mode hides images and makes the macro run faster
	setBatchMode(true);
	
	//print("in analyze puncta");

	//if autoCellBody roi was selected, runs the autoCellBody function
	//to find the center coordinates of the cell and makes a circle with
	//the enetered radius around those coordinates,
	//then saves it to a zip for future use
	if(roiType == "Auto Cell Body"){
		centerCoords = autoCellBody(dir1);
		if (centerCoords == "error"){
			roiType = "Circle";
		}
		else{
			centerArray = split(centerCoords,",");
			roiX = centerArray[0];
			roiY = centerArray[1];
		}
	}

	if(roiType == "Cell Territory"){
		centerCoords = autoTerritory(dir1, territoryMode);
		if (centerCoords == "error"){
			print("Cell Territory ROI method failed");
			roiType = "custom";
		}
		if (centerCoords == "saved roi"){
			roiPath = File.getParent(dir1) + File.separator + File.getNameWithoutExtension(dir1) + "_territory.roi";
		}
		else{
			centerArray = split(centerCoords,",");
			roiX = centerArray[0];
			roiY = centerArray[1];
		}
	}
	
	//opens the image, splits the channels and closes the blue channel
	open(dir1);

	print("dir1 is " + dir1);
	titleArray = split(dir1, "/");
	title = titleArray[titleArray.length-1];

	print("indexOf " + indexOf(title, "Output"));

	titleTemp = title;
	
	if (indexOf(title, "Output") >= 0){
		z = indexOf(title, "Output");
		print("z is " + z);
		titleTemp = substring(title, z + 7, lengthOf(title));
	}
	
	print("title is " + title);
	run("Select All");
	
	getPixelSize(unit, pixelWidth, pixelHeight);
	 
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	run("Split Channels");
	if (channelType == "2 Channel Colocalization (RG)"){
		//close blue
		close(title + " (blue)");
	}
	
	
	//Analyze red puncta
	//The subtract background and Gaussian blur filters are applied 
	selectWindow(title + " (red)");
	splitName = split(titleTemp, ".");
	print("splitName is " + splitName[0]);
	run("Select All");

	if(rotateControlBool == true){
		run("Rotate 90 Degrees Right");
	}

	if(scrmbleControlBool == true){
		imgScrmbl();
		setBatchMode("exit and display");
		waitForUser("check scrambled image");
	}
	
	if (noiseBool == true){
		run("Subtract Background...", "rolling=50");
		//Nicola Allen's Lab uses the same Gaussian Blur
		//for their puncta analysis
		run("Gaussian Blur...", "sigma=0.57");
	}

	
	if (brightBool == true){
		run("Enhance Contrast...", "saturated="+brightPercent+" equalize");
	}

	if (threshType == "Percent Histogram"){
		//Calculates histogram and then thresholds to image to 
		//include the top redHisto% of intensity values
		percentThreshold(redHisto);
		//stores the lower threshold
		getThreshold(lower, upper);
		redLower = lower;
		redUpper = upper;
		run("Duplicate...", "title=red_thresholded");
		selectWindow("red_thresholded");
		setThreshold(lower, upper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}
		

	}

	if (threshType == "Manual"){
		//uses percent Threshold for starting point
		percentThreshold(redHisto);
		//shows image for manual thresholding
		run("Threshold...");
		setBatchMode("show");
		waitForUser("Set Threshold and click OK");
		getThreshold(lower, upper);
		redLower = lower;
		redUpper = upper;
		run("Duplicate...", "title=red_thresholded");
		selectWindow("red_thresholded");
		setThreshold(lower, upper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}
	}

	if (threshType == "Fixed Value"){
		setThreshold(setRedT, 255);
		getThreshold(lower, upper);
		redLower = lower;
		redUpper = upper;
		run("Duplicate...", "title=red_thresholded");
		selectWindow("red_thresholded");
		setThreshold(lower, upper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}
	}

	if (threshType == "fromFile"){
		redLower = redLowArray[iterator];
		redUpper = redUpArray[iterator];
		setThreshold(redLower, redUpper);
		run("Duplicate...", "title=red_thresholded");
		run("Duplicate...", "title=red_thresholded");
		selectWindow("red_thresholded");
		setThreshold(redLower, redUpper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}
	}

	if (threshType == "FIJI auto"){
		run("Auto Threshold", "method=" + redTMethod);
		getThreshold(lower, upper);

		//adjust lowerT
		lower = lower * redAutoFactor + redAutoConstant;
		
		print(lower);
		setThreshold(lower, upper);
		redLower = lower;
		redUpper = upper;
		print("lower is " + lower);

		run("Duplicate...", "title=red_thresholded");
		selectWindow("red_thresholded");
		setThreshold(lower, upper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}
	}

	if (threshType == "ilastik"){


		imgTitle = getTitle();
		run("Run Pixel Classification Prediction for Syn_Bot", "projectfilename=["+ilpRedDir+"] inputimage=["+imgTitle+"] pixelclassificationtype=Probabilities");

		h5Path_in = getDirectory("imagej")+ File.separator + "ilastik4ij_in_raw.h5";
		h5Path_out = getDirectory("imagej")+ File.separator + "ilastik4ij_out.h5";
		print(h5Path_out);

		run("Import HDF5 for Syn_Bot", "select=["+h5Path_out+"] datasetname=/exported_data axisorder=tzyxc");

		//setBatchMode("exit and display");

		indexIlastikOut = -1;

		imgList = getList("image.titles");
		for (k = 0; k < imgList.length; k++) {
			print("Image " + k + " is " +imgList[k]);
			if (indexOf(imgList[k], "exported_data")>=0) {
				indexIlastikOut = k;
				print("output found " + k);
			}
		}

		//Selects the ilastik output image
		selectImage(indexIlastikOut + 1);
		
		saveAs("Tiff", dir2 + splitName[0] + "ilastik_red");

		ilastikOutRed = getTitle();

		File.delete(h5Path_in);
		File.delete(h5Path_out);
		
		run("8-bit");
		
		run("Auto Threshold", "method=Default white");
		
		//setBatchMode("exit and display");
		//waitForUser("before erode");
		//TODO: test erode choice
		run("Convert to Mask", "method=Default background=Dark calculate black");
			
		//waitForUser("after masking");
		
		
		if(erodeChoice == "yes"){
			setOption("BlackBackground", true);
			run("Erode", "stack");
		}
			
		//waitForUser("after erode");
		
		run("Auto Threshold", "method=Default white");
		//end changes

		getThreshold(lower, upper);
		print(lower);
		redLower = lower;
		redUpper = upper;
		print("lower is " + lower);

		run("Duplicate...", "title=red_thresholded");
		selectWindow("red_thresholded");
		setThreshold(lower, upper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}

		//setBatchMode("hide");
		
	}

	if (threshType == "Pre-Thresholded"){
		run("Invert");
		run("Auto Threshold", "method=Default dark");
		getThreshold(lower, upper);

		
		print(lower);
		setThreshold(lower, upper);
		redLower = lower;
		redUpper = upper;
		print("lower is " + lower);

		run("Duplicate...", "title=red_thresholded");
		selectWindow("red_thresholded");
		setThreshold(lower, upper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}
	}

	//if custom roi was seleceted, gives user time to draw there roi
	//then saves it to a zip for future use
	if(roiType == "custom"){
		setBatchMode("show");
		waitForUser("Select custom ROI");
		roiManager("add");
		roiManager("save",dir2+splitName[0]+"_roi.zip");
		setBatchMode("hide");
	}
	//if oval roi was seleceted, gives user time to select the center of
	//the roi, then makes a circle with the entered radius, 
	//then saves it to a zip for future use
	if(roiType == "Circle"){
		setBatchMode("show");
		setTool("point");
		waitForUser("Select center of ROI and click OK");
		Roi.getBounds(x, y, width, height);
		makeOval(x - roiR, y - roiR, roiR*2, roiR*2);
		roiManager("add");
		roiManager("save",dir2+splitName[0]+"_roi.zip");
		setBatchMode("hide");
	}

	if(roiType == "Auto Cell Body") {
		//makeOval take top left coords, width, height
		makeOval(roiX - roiR, roiY - roiR, 2*roiR, 2*roiR);
		roiManager("add");
		roiManager("save",dir2+splitName[0]+"_roi.zip");
	}

	if(roiType == "Cell Territory") {
		if (centerCoords == "saved roi"){
			//roiPath ="D:/Eroglu_lab/images/vamp2_test_subset/VGAT_Gephyrin/control_gfap_mcx/Output/220224_L23-CONTROL-P21-42-C9 MICE-GFAP_MCX568-VGAT647-GEPHYRIN95488-V1_0002-1_territory.roi";
			//"roiPath: D:\Eroglu_lab\images\vamp2_test_subset\VGAT_Gephyrin\control_gfap_mcx\Output\220224_L23-CONTROL-P21-42-C9 MICE-GFAP_MCX568-VGAT647-GEPHYRIN95488-V1_0002-1.roi"
			print("roiPath: " + roiPath); 
			roiManager("open", roiPath);
			roiManager("Select", 0);
		}
		else{
			//makeRectangle takes the top left coords, width, height
			makeRectangle(roiX - (roiWidth/2.0), roiY - (roiWidth/2.0), roiWidth, roiWidth);
			roiManager("add");
			roiManager("save",dir2+splitName[0]+"_roi.zip");
		}
	}

	//setBatchMode("exit and display");
	//waitForUser("before analyze particles");
	
	//open roiManager
	run("ROI Manager...");
	
	roiManager("reset");
	//runs Analyze Particles plugin using minPixel
	run("Analyze Particles...", "size=" + redMinPixel + "-" + redMaxString + " pixel show=Overlay display exclude clear summarize add");
	close("Summary");
	
	//waitForUser("after analyze particles");
	
	numRois = roiManager("count");
	
	print("numRois is: " + numRois);
	
	//add puncta to roiManager if it is empty
	if(numRois == 0){
		roiManager("add");
	}

	//create a new image with just the red puncta from the rois, 
	//this gets rid of any small particles that can confuse pixel mode
	
	
	Stack.getDimensions(width, height, channels, slices, frames);
	
	if(indexOf(getInfo("os.name"), "Windows") >= 0){
		newImage("From_ROI", "8-bit black", width, height, 1);
		roiManager("Set Fill Color", "yellow");
		roiManager("fill");
		roiManager("Show All without labels");
		run("Flatten");
	}
	if(indexOf(getInfo("os.name"), "Mac") >= 0){
		//newImage("From_ROI", "8-bit black", width, height, 1);
		Overlay.flatten;
		rename("From_ROI");
	}
	//setBatchMode("exit and display");
	//waitForUser("Before making From ROI");
	
	setThreshold(1, 255);
	run("Convert to Mask");
	close("red_thresholded");
	selectWindow("From_ROI-1");
	rename("red_thresholded");
	close("From_ROI");
	
	//waitForUser("After From ROI");
	
	//save the red thresholded image
	saveAs("tiff", dir2 + splitName[0] + "_redThresholded_" + toString(currentOffset) + ".tiff");
	//saving changes the name, so I will change it back for simplicity
	rename("red_thresholded");

	print("before first save");
	print("splitName[0] " + splitName[0]);
	//saves all red puncta coordinates and area (and other stats) to
	//a csv file "redResults"
	if(isOpen("Results")){
		print("save to " + dir2 + splitName[0] + "_redResults_" + toString(currentOffset) + ".csv");
		saveAs("Results", dir2 + splitName[0] + "_redResults_" + toString(currentOffset) + ".csv");
	}
	else{
		print("no results window");
		//TODO: add way to keep going to next image if no red puncta
	}

	
	//makes 3 arrays to store the x, y and radius values
	//of each red puncta (adapted from Richard Sriworarat)
	//the total number of red puncta 
	redCount = getValue("results.count");
	//an array of all red puncta x values
	redX = newArray(redCount);
	//an array of all red puncta y values
	redY = newArray(redCount);
	//an array of all red puncta radius values
	redR = newArray(redCount);

	//calculates the radius of each puncta from the area and populates
	//the red arrrays with appropriate values
	for (i = 0; i < redCount; i++) {
		redX[i] = getResult("X", i);
		redY[i] = getResult("Y", i);
		redR[i] = sqrt(getResult("Area", i) / PI);
	}
	
	roiManager("reset");
	//Analyze green puncta
	//The subtract background and Gaussian blur filters are applied
	selectWindow(title + " (green)");
	if(noiseBool == true){
		run("Subtract Background...", "rolling=50");
		run("Gaussian Blur...", "sigma=0.57");
	}

	if (brightBool == true){
		run("Enhance Contrast...", "saturated="+brightPercent+" equalize");
	}

	if (threshType == "Percent Histogram"){
		//Calculates histogram and then thresholds to image to 
		//include the top redHisto% of intensity values
		percentThreshold(greenHisto);
		//stores the lower threshold
		getThreshold(lower, upper);
		greenLower = lower;
		greenUpper = upper;
		
		run("Duplicate...", "title=green_thresholded");
		selectWindow("green_thresholded");
		setThreshold(lower, upper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}
	}

	if (threshType == "Manual"){
		//uses percent Threshold for starting point
		percentThreshold(greenHisto);
		//shows image for manual thresholding
		run("Threshold...");
		setBatchMode("show");
		waitForUser("Set Threshold and click OK");
		getThreshold(lower, upper);
		greenLower = lower;
		greenUpper = upper;
		run("Duplicate...", "title=green_thresholded");
		selectWindow("green_thresholded");
		setThreshold(lower, upper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}
	}

	if (threshType == "Fixed Value"){
		setThreshold(setGreenT, 255);
		getThreshold(lower, upper);
		greenLower = lower;
		greenUpper = upper;
		run("Duplicate...", "title=green_thresholded");
		selectWindow("green_thresholded");
		setThreshold(lower, upper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}
	}

	if (threshType == "fromFile"){
		greenLower = greenLowArray[iterator];
		greenUpper = greenUpArray[iterator];
		setThreshold(greenLower, greenUpper);
		run("Duplicate...", "title=green_thresholded");
		selectWindow("green_thresholded");
		setThreshold(greenLower, greenUpper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}
	}

	if (threshType == "FIJI auto"){
		run("Auto Threshold", "method=" + greenTMethod);
		getThreshold(lower, upper);

		//adjust lowerT
		lower = lower * greenAutoFactor + greenAutoConstant;

		
		setThreshold(lower, upper);
		greenLower = lower;
		greenUpper = upper;
		run("Duplicate...", "title=green_thresholded");
		selectWindow("green_thresholded");
		setThreshold(lower, upper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}
	}

	if (threshType == "ilastik"){

		//setBatchMode("exit and display");

		imgTitle = getTitle();
		
		run("Run Pixel Classification Prediction for Syn_Bot", "projectfilename=["+ilpGreenDir+"] inputimage=["+imgTitle+"] pixelclassificationtype=Probabilities");

		h5Path_in = getDirectory("imagej")+ File.separator + "ilastik4ij_in_raw.h5";
		h5Path_out = getDirectory("imagej")+ File.separator + "ilastik4ij_out.h5";
		print(h5Path_out);

		run("Import HDF5 for Syn_Bot", "select=["+h5Path_out+"] datasetname=/exported_data axisorder=tzyxc");

		//setBatchMode("exit and display");

		indexIlastikOut = -1;

		imgList = getList("image.titles");
		for (k = 0; k < imgList.length; k++) {
			print("Image " + k + " is " +imgList[k]);
			if (indexOf(imgList[k], "exported_data")>=0) {
				indexIlastikOut = k;
				print("output found " + k);
			}
		}

		
		
		//Selects the ilastik output image
		selectImage(indexIlastikOut + 1);
		print("name before save " + getTitle());
		
		saveAs("Tiff", dir2 + splitName[0] + "ilastik_green");

		ilastikOutGreen = getTitle();
		print(ilastikOutGreen);

		File.delete(h5Path_in);
		File.delete(h5Path_out);
		
		run("8-bit");
		
		run("Auto Threshold", "method=Default white");
		
		//setBatchMode("exit and display");
		//waitForUser("before erode");
		//TODO: test erode choice
		run("Convert to Mask", "method=Default background=Dark calculate black");
			
		//waitForUser("after masking");
		
		
		if(erodeChoice == "yes"){
			setOption("BlackBackground", true);
			run("Erode", "stack");
		}
			
		//waitForUser("after erode");
		
		run("Auto Threshold", "method=Default white");
		//end changes

		getThreshold(lower, upper);
		print(lower);
		greenLower = lower;
		greenUpper = upper;
		print("lower is " + lower);
		
		run("Duplicate...", "title=green_thresholded");
		selectWindow("green_thresholded");
		setThreshold(lower, upper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}
		
	}

	if (threshType == "Pre-Thresholded"){
		run("Invert");
		run("Auto Threshold", "method=Default dark");
		getThreshold(lower, upper);

		
		print(lower);
		setThreshold(lower, upper);
		greenLower = lower;
		greenUpper = upper;
		print("lower is " + lower);

		run("Duplicate...", "title=green_thresholded");
		selectWindow("green_thresholded");
		setThreshold(lower, upper);
		if (analysisType == "Pixel-based"){
			run("Convert to Mask");
		}
	}

	//if roi was custom or Circle, loads the roi from the zip file
	if (roiType == "custom" || roiType == "Circle"){
		//setBatchMode("show");
		roiManager("open",dir2+splitName[0]+"_roi.zip");
		roiManager("select", 0);
		//waitForUser("check roi");
		//setBatchMode("hide");
	}
	//if roi was autoCellBody, makes a circle using the 
	//values calculated previously
	if (roiType == "Auto Cell Body"){
		makeOval(roiX - roiR, roiY - roiR, 2*roiR, 2*roiR);
	}

	//if roi was Cell Territory, makes a square using the 
	//values calculated previously
	if (roiType == "Cell Territory"){
		if (centerCoords == "saved roi"){
			print("roiPath: " + roiPath); 
			roiManager("open", roiPath);
			roiManager("Select", 0);
		}
		else {
			makeRectangle(roiX - (roiWidth/2.0), roiY - (roiWidth/2.0), roiWidth, roiWidth);
		}
	}

	
	//runs Analyze Particles plugin using minPixel
	run("Analyze Particles...", "size=" + greenMinPixel + "-"+ greenMaxString +" pixel show=Overlay display exclude clear summarize add");
	close("Summary");

	//create a new image with just the green puncta from the rois, 
	//this gets rid of any small particles that can confuse pixel mode
	Stack.getDimensions(width, height, channels, slices, frames);

	Stack.getDimensions(width, height, channels, slices, frames);
	if(indexOf(getInfo("os.name"), "Windows") >= 0){
		newImage("From_ROI", "8-bit black", width, height, 1);
		roiManager("Set Fill Color", "yellow");
		roiManager("fill");
		roiManager("Show All without labels");
		run("Flatten");
	}
	if(indexOf(getInfo("os.name"), "Mac") >= 0){
		//newImage("From_ROI", "8-bit black", width, height, 1);
		Overlay.flatten;
		rename("From_ROI");
	}
	
	setThreshold(1, 255);
	run("Convert to Mask");
	close("green_thresholded");
	selectWindow("From_ROI-1");
	rename("green_thresholded");
	close("From-ROI");
	
	//save the green thresholded image
	saveAs("tiff", dir2 + splitName[0] + "_greenThresholded_" + toString(currentOffset) + ".tiff");
	//saving changes the name, so I will change it back for simplicity
	rename("green_thresholded");


	//saves all green puncta coordinates and area (and other stats) to
	//a csv file "greenResults"
	if(isOpen("Results")){
		saveAs("Results", dir2 + splitName[0] + "_greenResults_" + toString(currentOffset) + ".csv");
	}
	else{
		print("no results window");
		
		//TODO: add tolerance of no green puncta
	}

	//makes 3 arrays to store the x, y and radius values
	//of each green puncta (adapted from Richard Sriworarat)
	//the total number of red puncta 
	greenCount = getValue("results.count");
	//an array of all green puncta x values
	greenX = newArray(greenCount);
	//an array of all green puncta y values
	greenY = newArray(greenCount);
	//an array of all green puncta radius values
	greenR = newArray(greenCount);

	//calculates the radius of each puncta from the area and populates
	//the green arrrays with appropriate values
	for (i = 0; i < greenCount; i++) {
		greenX[i] = getResult("X", i);
		greenY[i] = getResult("Y", i);
		greenR[i] = sqrt(getResult("Area", i) / PI);
	}

	close("Summary");
	close("Results");
	//close("ROI Manager");

	if (channelType == "3 Channel Colocalization (RGB)"){
		//Analyze blue puncta
		//The subtract background and Gaussian blur filters are applied
		selectWindow(title + " (blue)");
		if(noiseBool == true){
			run("Subtract Background...", "rolling=50");
			run("Gaussian Blur...", "sigma=0.57");
		}
	
		if (brightBool == true){
			run("Enhance Contrast...", "saturated="+brightPercent+" equalize");
		}
	
		if (threshType == "Percent Histogram"){
			//Calculates histogram and then thresholds to image to 
			//include the top redHisto% of intensity values
			percentThreshold(blueHisto);
			//stores the lower threshold
			getThreshold(lower, upper);
			blueLower = lower;
			blueUpper = upper;
			
			run("Duplicate...", "title=blue_thresholded");
			selectWindow("blue_thresholded");
			setThreshold(lower, upper);
			if (analysisType == "Pixel-based"){
				run("Convert to Mask");
			}
		}
	
		if (threshType == "Manual"){
			//uses percent Threshold for starting point
			percentThreshold(blueHisto);
			//shows image for manual thresholding
			run("Threshold...");
			setBatchMode("show");
			waitForUser("Set Threshold and click OK");
			getThreshold(lower, upper);
			blueLower = lower;
			blueUpper = upper;
			run("Duplicate...", "title=blue_thresholded");
			selectWindow("blue_thresholded");
			setThreshold(lower, upper);
			if (analysisType == "Pixel-based"){
				run("Convert to Mask");
			}
		}
	
		if (threshType == "Fixed Value"){
			setThreshold(setBlueT, 255);
			getThreshold(lower, upper);
			blueLower = lower;
			blueUpper = upper;
			run("Duplicate...", "title=blue_thresholded");
			selectWindow("blue_thresholded");
			setThreshold(lower, upper);
			if (analysisType == "Pixel-based"){
				run("Convert to Mask");
			}
		}

		//From file 3 channel is not yet supported
		if (threshType == "fromFile"){
			exit("Error: From file 3 channel is not yet supported");
		}
			/*
			blueLower = blueLowArray[iterator];
			greenUpper = greenUpArray[iterator];
			setThreshold(greenLower, greenUpper);
			run("Duplicate...", "title=green_thresholded");
			selectWindow("green_thresholded");
			setThreshold(lower, upper);
			if (analysisType == "Pixel-based"){
				run("Convert to Mask");
			}
		}
		*/
	
		if (threshType == "FIJI auto"){
			run("Auto Threshold", "method=" + blueTMethod);
			getThreshold(lower, upper);
	
			//adjust lowerT
			lower = lower * blueAutoFactor + blueAutoConstant;
	
			
			setThreshold(lower, upper);
			blueLower = lower;
			blueUpper = upper;
			run("Duplicate...", "title=blue_thresholded");
			selectWindow("blue_thresholded");
			setThreshold(lower, upper);
			if (analysisType == "Pixel-based"){
				run("Convert to Mask");
			}
		}
	
		if (threshType == "ilastik"){
	
			//setBatchMode("exit and display");
	
			imgTitle = getTitle();
			
			run("Run Pixel Classification Prediction for Syn_Bot", "projectfilename=["+ilpBlueDir+"] inputimage=["+imgTitle+"] pixelclassificationtype=Probabilities");
	
			h5Path_in = getDirectory("imagej")+ File.separator + "ilastik4ij_in_raw.h5";
			h5Path_out = getDirectory("imagej")+ File.separator + "ilastik4ij_out.h5";
			print(h5Path_out);
	
			run("Import HDF5 for Syn_Bot", "select=["+h5Path_out+"] datasetname=/exported_data axisorder=tzyxc");
	
			//setBatchMode("exit and display");
	
			indexIlastikOut = -1;
	
			imgList = getList("image.titles");
			for (k = 0; k < imgList.length; k++) {
				print("Image " + k + " is " +imgList[k]);
				if (indexOf(imgList[k], "exported_data")>=0) {
					indexIlastikOut = k;
					print("output found " + k);
				}
			}
	
			
			
			//Selects the ilastik output image
			selectImage(indexIlastikOut + 1);
			print("name before save " + getTitle());
			
			saveAs("Tiff", dir2 + splitName[0] + "ilastik_blue");
	
			ilastikOutBlue = getTitle();
			print(ilastikOutBlue);
	
			File.delete(h5Path_in);
			File.delete(h5Path_out);
			
			run("8-bit");
			
			run("Auto Threshold", "method=Default white");
			
			//setBatchMode("exit and display");
			//waitForUser("before erode");
			//TODO: test erode choice
			run("Convert to Mask");
			
			//waitForUser("after masking");
		
		
			if(erodeChoice == "yes"){
				run("Erode");
			}
			
			//waitForUser("after erode");
		
			run("Auto Threshold", "method=Default white");
			//end changes
	
			getThreshold(lower, upper);
			print(lower);
			blueLower = lower;
			blueUpper = upper;
			print("lower is " + lower);
			
			run("Duplicate...", "title=blue_thresholded");
			selectWindow("blue_thresholded");
			setThreshold(lower, upper);
			if (analysisType == "Pixel-based"){
				run("Convert to Mask");
			}
			
		}
	
		if (threshType == "Pre-Thresholded"){
			run("Invert");
			run("Auto Threshold", "method=Default dark");
			getThreshold(lower, upper);
	
			
			print(lower);
			setThreshold(lower, upper);
			blueLower = lower;
			blueUpper = upper;
			print("lower is " + lower);
	
			run("Duplicate...", "title=blue_thresholded");
			selectWindow("blue_thresholded");
			setThreshold(lower, upper);
			if (analysisType == "Pixel-based"){
				run("Convert to Mask");
			}
		}
	
		//if roi was custom or Circle, loads the roi from the zip file
		if (roiType == "custom" || roiType == "Circle"){
			//setBatchMode("show");
			roiManager("open",dir2+splitName[0]+"_roi.zip");
			roiManager("select", 0);
			//waitForUser("check roi");
			//setBatchMode("hide");
		}
		//if roi was autoCellBody, makes an circle using the 
		//values calculated previously
		if (roiType == "Auto Cell Body"){
			makeOval(roiX - roiR, roiY - roiR, 2*roiR, 2*roiR);
		}

		//if roi was Cell Territory, makes a square using the 
		//values calculated previously
		if (roiType == "Cell Territory"){
			makeRectangle(roiX - (roiWidth/2.0), roiY - (roiWidth/2.0), roiWidth, roiWidth);
		}
		
		//runs Analyze Particles plugin using minPixel
		run("Analyze Particles...", "size=" + blueMinPixel + "-"+blueMaxString+" pixel show=Overlay display exclude clear summarize add");
		close("Summary");

		//create a new image with just the blue puncta from the rois, 
		//this gets rid of any small particles that can confuse pixel mode

		Stack.getDimensions(width, height, channels, slices, frames);
		if(indexOf(getInfo("os.name"), "Windows") >= 0){
			newImage("From_ROI", "8-bit black", width, height, 1);
			roiManager("fill");
		}
		if(indexOf(getInfo("os.name"), "Mac") >= 0){
			//newImage("From_ROI", "8-bit black", width, height, 1);
			Overlay.flatten;
			rename("From_ROI");
		}
		
		setThreshold(1, 255);
		run("Convert to Mask");
		close("blue_thresholded");
		selectWindow("From_ROI");
		rename("blue_thresholded");
		
		//saves all blue puncta coordinates and area (and other stats) to
		//a csv file "blueResults"
		saveAs("Results", dir2 + splitName[0] + "_blueResults_" + toString(currentOffset) + ".csv");
	
		//makes 3 arrays to store the x, y and radius values
		//of each blue puncta (adapted from Richard Sriworarat)
		//the total number of red puncta 
		blueCount = getValue("results.count");
		//an array of all blue puncta x values
		blueX = newArray(blueCount);
		//an array of all green puncta y values
		blueY = newArray(blueCount);
		//an array of all green puncta radius values
		blueR = newArray(blueCount);
	
		//calculates the radius of each puncta from the area and populates
		//the blue arrrays with appropriate values
		for (i = 0; i < blueCount; i++) {
			blueX[i] = getResult("X", i);
			blueY[i] = getResult("Y", i);
			blueR[i] = sqrt(getResult("Area", i) / PI);
		}
	
		close("Summary");
		close("Results");
		//close("ROI Manager");
	}
	
	//runs actual colocalization calculations using circle or pixel based methods for either 2 or 3 channels
	print("Counting colocalizations...");

	if (analysisType == "Circle-based" && channelType == "2 Channel Colocalization (RG)"){
		//creates a Results table that will be the input to the Coloc_Calc
		//plugin
		Table.create("Results");
		Table.setColumn("redX", redX);
		Table.setColumn("redY", redY);
		Table.setColumn("redR", redR);
		Table.setColumn("greenX", greenX);
		Table.setColumn("greenY", greenY);
		Table.setColumn("greenR", greenR);
	
		//runs the Coloc_Calc plugin on the open "Results" window
		//the plugin will rename this to "oldResults" and 
		//display its output as a new "Results" table
		run("Syn_Bot_Helper");
	}

	if (analysisType == "Pixel-based" && channelType == "2 Channel Colocalization (RG)"){
		imageCalculator("AND create", "red_thresholded", "green_thresholded");
		rename(title + "_colocs");

	
		//set colocMinPixel to 0, could be changed
		colocMinPixel = 0;
		//count colocs in AND image
		run("Analyze Particles...", "size=" + colocMinPixel + "-Infinity pixel show=Overlay display exclude clear summarize add");
		close("Summary");

		selectWindow(title + "_colocs");
		saveAs("tiff", dir2 + splitName[0] + "_coloc_binary");
	}

////////////////////////////////////////
	//3 Channel versions
	if (analysisType == "Circle-based" && channelType == "3 Channel Colocalization (RGB)"){
		//creates a Results table that will be the input to the Coloc_Calc
		//plugin
		Table.create("Results");
		Table.setColumn("redX", redX);
		Table.setColumn("redY", redY);
		Table.setColumn("redR", redR);
		Table.setColumn("greenX", greenX);
		Table.setColumn("greenY", greenY);
		Table.setColumn("greenR", greenR);
		Table.setColumn("blueX", blueX);
		Table.setColumn("blueY", blueY);
		Table.setColumn("blueR", blueR);
	
		//runs the Syn_Bot_Triple plugin on the open "Results" window
		//the plugin will rename this to "oldResults" and 
		//display its output as a new "Results" table
		run("Console");
		run("Syn_Bot_Triple");
	}

	if (analysisType == "Pixel-based" && channelType == "3 Channel Colocalization (RGB)"){
		imageCalculator("AND create", "red_thresholded", "green_thresholded");
		rename(title + "_colocsRG");

		imageCalculator("AND create", title + "_colocsRG", "blue_thresholded");
		rename(title + "_colocs");
	
		//set colocMinPixel to 0, could be changed
		colocMinPixel = 0;
		//count colocs in AND image
		run("Analyze Particles...", "size=" + colocMinPixel + "-Infinity pixel show=Overlay display exclude clear summarize add");
		close("Summary");

		selectWindow(title + "_colocs");
		saveAs("tiff", dir2 + splitName[0] + "_coloc_binary");
	}
	

	//saves the output results table of Coloc_Calc, all the coloc puncta
	//coordinates, to a .csv file "colocResults"
	if(isOpen("Results")){
		saveAs("Results", dir2 + splitName[0] + "_colocResults_" + toString(currentOffset) + ".csv");
	}
	else{
		print("no results found");
	}
	//stores the values from the Coloc_Calc plugin output Results table
	//as arrays
	
	//check if there is no results window
	if (isOpen("Results") == false){
		print("no results window");
		colocX = 0;
		colocY = 0;
		colocArea = 0;
		colocCount = 0;
	}
	if (isOpen("Results") == true){

		selectWindow("Results");
		currentHeadings = Table.headings;
		if (analysisType == "Circle-based"){
			if(indexOf(currentHeadings, "colocX")<0){
				colocX = 0;
				colocY = 0;
				colocArea = 0;
				colocCount = 0;
			}
			else{
				colocX = Table.getColumn("colocX");
				colocY = Table.getColumn("colocY");
				colocArea = Table.getColumn("colocArea");
				colocCount = colocX.length;
			}
			
		}
		if (analysisType == "Pixel-based"){
			if(indexOf(currentHeadings, "X")<0){
				colocX = 0;
				colocY = 0;
				colocArea = 0;
				colocCount = 0;
			}
			else{
				colocX = Table.getColumn("X");
				colocY = Table.getColumn("Y");
				colocArea = Table.getColumn("Area");
				colocCount = colocX.length;
			}
		}
	}

	//Enhance contrast to help visualize puncta in feedback image
	selectWindow(title + " (red)");
	run("Enhance Contrast", "saturated=1");
	selectWindow(title + " (green)");
	run("Enhance Contrast", "saturated=1");

	if (channelType == "3 Channel Colocalization (RGB)"){
		selectWindow(title + " (blue)");
		run("Enhance Contrast", "saturated=1");
	}

	//merge the current image to produce the feedback image
	if (channelType == "2 Channel Colocalization (RG)"){
		run("Merge Channels...", "c1=["+title+" (red)] c2=["+title+" (green)] create");
	}

	if (channelType == "3 Channel Colocalization (RGB)"){
		run("Merge Channels...", "c1=["+title+" (red)] c2=["+title+" (green)] c3=["+title+" (blue)] create");
	}
	
	run("Select None");
	print("colocCount is " + colocCount);

	//exits batch mode so that the puncta can be drawn correctly
	setBatchMode("show");
	setBatchMode(false);
	roiManager("reset");
	
	//draws each colocalized puncta onto the merged feedback image
	//by first adding each to the roi manager
	for(k = 0; k < colocCount; k++){
		makePoint(colocX[k], colocY[k],"dot white small"); 
		roiManager("Add");
	}

	//the colocalized puncta in the roi manager are then drawn on the
	//feedback image if there are any
	if (colocCount > 0){
		run("From ROI Manager");
	}	

	
	//Saves the feedback image showing colocalized puncta counted
	saveAs("tiff", dir2 + splitName[0] + "_colocs");
	close("Results");
	close("oldResults");
	run("Close All");
	close("ROI Manager");

	imageList[iterator] = title;
	redList[iterator] = redX.length;
	greenList[iterator] = greenX.length;
	colocList[iterator] = colocCount;
	offsetUsed[iterator] = currentOffset;
	lowerRedT[iterator] = redLower;
	upperRedT[iterator] = redUpper;
	lowerGreenT[iterator] = greenLower;
	upperGreenT[iterator] = greenUpper;
	imageScale[iterator] = pixelWidth;
	imageUnit[iterator] = unit;

	if (channelType == "3 Channel Colocalization (RGB)"){
		blueList[iterator] = blueX.length;
		lowerBlueT[iterator] = blueLower;
		upperBlueT[iterator] = blueUpper;
	}

	//end of analyzePuncta function
}

//Function to automatically find the center of a cultured neuron using a
//postsynaptic marker in the red channel
function autoCellBody(dir1){
	open(dir1);
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	title = getTitle();
	selectWindow(title);
	run("Split Channels");
	
	selectWindow(title + " (red)");
	close(title + " (green)");
	close(title + " (blue)");

	//Gaussian Blur obscures the cell's branches, leaving only the soma
	run("Gaussian Blur...", "sigma=60");
	//This auto-thresholds the soma to give a solid shape
	run("Auto Threshold", "method=MaxEntropy white");
	//This creates an ellipse in FIJI around the bounds of the soma shape
	run("Analyze Particles...", "  show=Ellipses display exclude clear summarize add");
	//The center coordinates of the shape are recorded and stored
	xArray = Table.getColumn("X");
	if (xArray.length > 1) {
//		Dialog.create("autoCellBody Error");
//		Dialog.addMessage("Multiple Objects Detected");
//		Dialog.addMessage("Switching to Circle ROI");
//		beep();
//		Dialog.show();
//		return "error";
		print("Multiple Objects Detected");
		print("Analyzing first object");
		
	}
	centerX = getResult("X",0);
	centerY = getResult("Y",0);
	print(centerX); 
	print(centerY);
	close("Drawing of " + title + " (red)");
	close("Summary");
	close("Results");
	close();
	roiManager("reset");
	return d2s(centerX, 3) + "," + d2s(centerY, 3);
}

//Modified version of autoCellBody to make a rectangle in the 
//middle of the astrocyte image in the blue channel
function autoTerritory(dir1, territoryMode){
	
	//close Results if it is open
	if(isOpen("Results")){
		close("Results");
	}
	
	open(dir1);
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	title = getTitle();
	selectWindow(title);
	run("Split Channels");
	
	selectWindow(title + " (blue)");
	close(title + " (green)");
	close(title + " (red)");

	//set to middle slice
	getDimensions(width, height, channels, slices, frames);
	//if there are multiple slices, set the image to the middle slice
	if(slices > 1){
		setSlice(slices/2);
	}

	//Gaussian Blur obscures the cell's branches, leaving only the soma
	run("Gaussian Blur...", "sigma=60");
	//This auto-thresholds the soma to give a solid shape
	run("Auto Threshold", "method=MaxEntropy white");
	//This creates an ellipse in FIJI around the bounds of the soma shape
	run("Analyze Particles...", "  show=Ellipses display exclude clear summarize add");
	//The center coordinates of the shape are recorded and stored
	if(isOpen("Results") == false){
		//setBatchMode("exit and display");
		print("no cell found in autoTerritory");
		//waitForUser("manually fix and then click OK");
		//setBatchMode("hide");
		resultsBool = false;
		count = 0;
		while (resultsBool == false && count < 50){
			//close ellipse drawing
			close();
			run("Dilate");
			setThreshold(100, 255);
			run("Analyze Particles...", "  show=Ellipses display exclude clear summarize add");
			resultsBool = isOpen("Results");
			count += 1;
		}
		if (count >= 50){
			exit("could not find cell");
		}
	}
	
	selectWindow("Results");
	xArray = Table.getColumn("X");
	print(xArray[0]);
	if (xArray.length > 1) {
//		Dialog.create("autoTerritory Error");
//		Dialog.addMessage("Multiple Objects Detected");
//		beep();
//		Dialog.show();
//		return "error";
		print("Multiple Objects Detected");
		print("Analyzing first object");
	}
	centerX = getResult("X",0);
	centerY = getResult("Y",0);
	print(centerX); 
	print(centerY);
	close("Drawing of " + title + " (blue)");
	close("Summary");
	close("Results");
	close();
	roiManager("reset");

	if(territoryMode == "center"){
		return d2s(centerX, 3) + "," + d2s(centerY, 3);
	}

	if(territoryMode == "offset"){
		//open image again to get the outer territory
		open(dir1);
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
		run("Set Measurements...", "area mean standard centroid center bounding fit redirect=None decimal=3");
		//set measurements so that an ellipse will be fit to the territory
		title = getTitle();
		selectWindow(title);
		run("Split Channels");
		
		selectWindow(title + " (blue)");
		close(title + " (green)");
		close(title + " (red)");
	
		//set to middle slice
		getDimensions(width, height, channels, slices, frames);
		//if there are multiple slices, set the image to the middle slice
		if(slices > 1){
			setSlice(slices/2);
		}
		run("Gaussian Blur...", "sigma=60");
		//This auto-thresholds the soma to give a solid shape
		run("Auto Threshold", "method=Huang2 white");

		//run analyze particles to get territory into roimanager
		run("Analyze Particles...", "display exclude clear summarize add");

		selectWindow("Summary");
		//length of major axis of ellipse fit to territory
		ellipseMajor = Table.get("Major", 0);
		//length of minor axis of ellipse fit to territory
		ellipseMinor = Table.get("Minor", 0);
		//angle from the major axis to the horizontal
		//angle starts with 0 being to the right and 180 being to the left
		ellipseAngle = Table.get("Angle", 0);
		print("ellipseAngle is " + ellipseAngle);

		if (0 < ellipseAngle && ellipseAngle < 90){
			angleSide = "right";
			print("top right"); 
		}
		if (90 < ellipseAngle && ellipseAngle < 180){
			angleSide = "left";
			print("top left"); 
		}
		

		//convert degrees to radians 
		angleRad = ellipseAngle * (PI/180.0); 

		angleRightBool = (indexOf(angleSide, "right") >= 0);


			//center assignment for testing
			//***Should be commented out for real use***
			//centerX = 532.0;
			//centerY = 580.0;

			//print("centerX set to " + centerX);


			

		if (angleRightBool == false){
			angleFinal = (2 * PI) - angleRad;
			//calculate the distance from the center to the furthest point of the ellips
			deltaX = (ellipseMajor * 0.5) * cos(angleFinal);
			deltaY = (ellipseMajor * 0.5) * sin(angleFinal);

			//calculate the midpoint between the center and 
			//furthest point to be the center of the ROI
			midX = centerX - (deltaX * 0.5);
			print("midX is " + midX);
			midY = centerY - (deltaY * 0.5);
			print("midY is " + midY);
		}

		if (angleRightBool == true){
			angleFinal = angleRad;
			//calculate the distance from the center to the furthest point of the ellips
			deltaX = (ellipseMajor * 0.5) * cos(angleFinal);
			deltaY = (ellipseMajor * 0.5) * sin(angleFinal);
			
			//calculate the midpoint between the center and 
			//furthest point to be the center of the ROI
			midX = centerX + (deltaX * 0.5);
			print("midX is " + midX);
			midY = centerY - (deltaY * 0.5);
			print("midY is " + midY);
		}

		//save the territory as an image
		splitName = split(dir1, ".");
		saveAs("tiff", splitName[0] + "_territory");

		//save the ellipse fit to the territory as an image
		roiManager("select", 0);
		run("Fit Ellipse");

		saveAs("tiff", splitName[0] + "_ellipse");

		close("Summary");
		close("Results");
		close();
		roiManager("reset");

		//set measurements back to normal
		run("Set Measurements...", "area mean standard centroid center bounding integrated display redirect=None decimal=3");

		return d2s(midX, 3) + "," + d2s(midY, 3);
				
	}
	
	if(territoryMode == "Whole Territory"){
		//open image again to get the outer territory
		open(dir1);
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
		run("Set Measurements...", "area mean standard centroid center bounding fit redirect=None decimal=3");
		//set measurements so that an ellipse will be fit to the territory
		title = getTitle();
		selectWindow(title);
		run("Split Channels");
		
		selectWindow(title + " (blue)");
		close(title + " (green)");
		close(title + " (red)");
	
		//set to middle slice
		getDimensions(width, height, channels, slices, frames);
		//if there are multiple slices, set the image to the middle slice
		if(slices > 1){
			setSlice(slices/2);
		}
		run("Gaussian Blur...", "sigma=60");
		
		//Huang2 thresholding doesn't work for mCherry cell fill
		//MaxEntropy seems better for mCherry
		//This auto-thresholds the soma to give a solid shape
		run("Auto Threshold", "method=MaxEntropy white");

		//run analyze particles to get territory into roimanager
		run("Analyze Particles...", "display exclude clear summarize add");
 
 		//TODO: error if there are no cells found
 		
		//save the territory as an roi
		roiManager("Select", 0);
		roiManager("Save", File.getParent(dir1) + File.separator + File.getNameWithoutExtension(dir1) + "_territory.roi");

		close("Summary");
		close("Results");
		close();
		roiManager("reset");

		//set measurements back to normal
		run("Set Measurements...", "area mean standard centroid center bounding integrated display redirect=None decimal=3");

		return "saved roi";
				
	}
	
}

/*function to threshold image to only include the top
n% of pixels in the intensity histogram based on: http://imagej.1557.x6.nabble.com/Threshold-as-a-percentage-of-image-histogram-td3695671.html
*/
function percentThreshold(percentIncluded){
	
	percentExcluded = 100 - percentIncluded;
	nBins = 256;
	getHistogram(values, count, nBins);
	size = count.length;
	// find culmulative sum
	totalPixels = getWidth() * getHeight();
	tissueValue = totalPixels * percentExcluded / 100;
	// cumulative sum of before
	cumSumValues = count;
	newLower = 0;
	for (i = 1; i<count.length; i++)
	{
	cumSumValues[i] += cumSumValues[i-1];
	}

	// find tissueValue
	for (i = 1; i<cumSumValues.length; i++)
	{
	if (cumSumValues[i-1] <= tissueValue && tissueValue <= cumSumValues[i]) {
	// output tissue threshold:
	newLower = i;
	//print("newLower is " + newLower);
		}
	}
	print("newLower is " + newLower);
	setThreshold(newLower,255);
}
	

//Z projects images by getting the Max Intensity projections of every
//3 Z-stacks and converting the projection to RGB before saving
function zProject(dir1, dir2, file) {
	setBatchMode(true);
	//use Bio-Formats open if image is not already a tif
	
	if (endsWith(file, "tif")){
		open(dir1+file);
		print("tif detected");
	}
	if (endsWith(file, "tiff")){
		open(dir1+file);
		print("tif detected");
	}
	if ((endsWith(file, "tif") != 1) && (endsWith(file, "tiff") != 1)){
		run("Bio-Formats Importer", "open=["+dir1+file+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		print("non-tif detected");
	}
	Stack.getDimensions(width, height, channels, slices, frames);
	num = floor(slices / 3);

	for (j = 1; j <= num; j++) {
		end = j * 3;
		start = end - 2;
		run("Z Project...", "start=" + j + " stop=" + end + " projection=[Max Intensity]");
		run("Channels Tool...");
		Stack.setDisplayMode("composite");
		run("Stack to RGB");
		saveAs("tiff", dir2 + substring(file,0,lengthOf(file)-4) + "-" +j);
		close();
		close();
	}

	close();
	selectWindow("Channels");
	run("Close");
}

//Runs the Z-Projection for all of the images in a directory
function projectPair(dir1, dirOut) {

	list  = getFileList(dir1);
	setBatchMode(true);

	for (i = 0; i < list.length; i++) {
		print("i" + i + ":" + list[i]);
		if(endsWith(list[i], ".ini")){
			continue;
		}
		if(endsWith(list[i], "/")){
			continue;
		}
		zProject(dir1, dirOut, list[i]);
	}
}

//assumes C4 is red and C3 is green to convert single stack images 
//with more than 3 channels to RGB and save them in the Z_projects folder
function processCellImages(dir1, dirOut) {
	list1  = getFileList(dir1);

	for (i = 0; i < list1.length; i++) {
		redChannel = 99;
		greenChannel = 99;
		blueChannel = 99;
		setBatchMode(true);
		currentImage = list1[i];
		print("i" + i + ":" + list1[i]);
		if(endsWith(currentImage, ".ini")){
			print("ini found: " + currentImage);
			continue;
		}
		if(endsWith(currentImage, "/")){
			print("/ found: " + currentImage);
			continue;
		}
		run("Bio-Formats Importer", "open=["+dir1 + currentImage+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		//open(dir1 + currentImage);
		getDimensions(width, height, channels, slices, frames);
		title = getTitle();
//		if(pickChannelsBool == false){
//		//asks the user to select channels if there are more than 3 channels
//		//Should be replaced by the pickChannels function
//			if (channels > 3 && redChannel == 99){
//				run("Split Channels");
//				setBatchMode("exit and display");
//				Dialog.create("Channels to use");
//				Dialog.addNumber("Red Channel:", 0);
//				Dialog.addNumber("Green Channel:", 0);
//				Dialog.addNumber("Blue Channel:", 0);
//				Dialog.show();
//				redChannel = Dialog.getNumber();
//				greenChannel = Dialog.getNumber();
//				blueChannel = Dialog.getNumber();
//				if(redChannel > 0 && greenChannel > 0 && blueChannel > 0){
//					run("Merge Channels...", "c1=[C"+redChannel+"-"+title+"] c2=[C"+greenChannel+"-"+title+"] c3=[C"+blueChannel+"-"+title+"] create");
//				}
//				if(redChannel > 0 && greenChannel > 0 && blueChannel == 0){
//					run("Merge Channels...", "c1=[C"+redChannel+"-"+title+"] c2=[C"+greenChannel+"-"+title+"] create");
//				
//				}
//				setBatchMode(true);
//	
//			}
//		}
		title = getTitle();
		selectWindow(title);
		run("RGB Color");
		saveAs(".tif", dirOut + File.separator +  currentImage);
		close("*");
	}
}

function checkRGB(currentImage) {

	setBatchMode(true);
	run("Bio-Formats Importer", "open=["+currentImage+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	
	title = getTitle();
	rgbBoolLoc = false;

	
	if(bitDepth() == 24) {
		rgbBoolLoc = true;
	}
	if(bitDepth() != 24){
		rgbBoolLoc = false;
	}
	print("bitDepth: " + bitDepth());
	print("rgbBoolLoc: " + rgbBoolLoc);

	close(title);

	return rgbBoolLoc;
}

function checkZStack(currentImage) {

	setBatchMode(true);
	run("Bio-Formats Importer", "open=["+currentImage+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	
	title = getTitle();
	
	Stack.getDimensions(width, height, channels, slices, frames);
	
	zProjectLoc = false;
	if(slices > 1) {
		zProjectBoolLoc = true;
	}
	if(slices == 1) {
		zProjectBoolLoc = false;
	}
	print("slices: " + slices);
	print("zProjectBoolLoc: " + zProjectBoolLoc);

	close(title);

	

	return zProjectBoolLoc;
}

function imgScrmbl(){
	// Shuffle Pixel Data
	// Jeffrey N. Murphy 2018-02-22 
	//from https://github.com/MurphysLab/ImageJ-Macros/blob/master/PixelShuffle.ijm

	//inputImg = getTitle();
	//ouputImg = run("Duplicate...", "title=["+inputImg+"]_scrmbl");
	// Get Values
	w = getWidth;
	h = getHeight;
	values = newArray(w*h);
	i = 0;
	for(y=0; y<h; y++){
		for(x=0; x<w; x++){
			values[i] = getPixel(x,y);
			i++;
		}
	}

	// Shuffle
	new_values = newArray(w*h);
	for(i=0; i<new_values.length; i++){
		j = round(random*(values.length-1));
		new_values[i] = values[j];
		values_a = Array.slice(values,0,j);
		values_b = Array.slice(values,j+1,values.length);
		values = Array.concat(values_a,values_b);
		showProgress(i,new_values.length);
	}

	// Re-Draw
	i = 0;
	for(y=0; y<h; y++){
		for(x=0; x<w; x++){
			setPixel(x,y,new_values[i]);
			i++;
		}
	}
	//close(inputImg);
	//selectWindow(outputImg);
	//rename(inputImg);
}

function pickChannels(currentImage){
	
	if (endsWith(currentImage, "tif")){
		open(currentImage);
		print("tif detected");
	}
	if (endsWith(currentImage, "tiff")){
		open(currentImage);
		print("tif detected");
	}
	if ((endsWith(currentImage, "tif") != 1) && (endsWith(currentImage, "tiff") != 1)){
		run("Bio-Formats Importer", "open=["+currentImage+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		print("non-tif detected");
	}
	
	title = getTitle();
	
	Stack.getDimensions(width, height, channels, slices, frames);
	
	run("Split Channels");
	setBatchMode("exit and display");
	Dialog.createNonBlocking("Channels to use");
	Dialog.addMessage("Set main channels to be counted as red, green, and blue in that order. \n Leave any channels not being used as 0");
	Dialog.addNumber("Red Channel:", 0);
	Dialog.addNumber("Green Channel:", 0);
	Dialog.addNumber("Blue Channel:", 0);
	Dialog.show();
	redChannel = Dialog.getNumber();
	greenChannel = Dialog.getNumber();
	blueChannel = Dialog.getNumber();
	channelsList = newArray(redChannel, greenChannel, blueChannel);
	return channelsList;
	setBatchMode(true);
	close("*");
}

//corrects the channels for a folder of images
function correctChannels(dir1, dirOut, channelsList){
	
	list  = getFileList(dir1);
	setBatchMode(true);

	for (i = 0; i < list.length; i++) {
		print("i" + i + ":" + list[i]);
		if(endsWith(list[i], ".ini")){
			continue;
		}
		if(endsWith(list[i], "/")){
			continue;
		}
		currentImage = dir1 + File.separator + list[i];
		
		run("Bio-Formats Importer", "open=["+currentImage+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	
		title = getTitle();
		
		Stack.getDimensions(width, height, channels, slices, frames);
		
		run("Split Channels");
		
		redChannel = channelsList[0];
		greenChannel = channelsList[1];
		blueChannel = channelsList[2];
		//Going to do the merging in a separate function 
		if(redChannel > 0 && greenChannel > 0 && blueChannel > 0){
			run("Merge Channels...", "c1=[C"+redChannel+"-"+title+"] c2=[C"+greenChannel+"-"+title+"] c3=[C"+blueChannel+"-"+title+"] create ignore");
		}
		if(redChannel > 0 && greenChannel > 0 && blueChannel == 0){
			run("Merge Channels...", "c1=[C"+redChannel+"-"+title+"] c2=[C"+greenChannel+"-"+title+"] create ignore");			
		}
		if(redChannel > 0 && greenChannel == 0 && blueChannel == 0){
			run("Merge Channels...", "c1=[C"+redChannel+"-"+title+"] create ignore");			
		}
		rename(title + "_corrected");
		run("Stack to RGB");
		saveAs("tiff", dirOut + File.separator + title + "_corrected");
		close("*");
	}

}

		
