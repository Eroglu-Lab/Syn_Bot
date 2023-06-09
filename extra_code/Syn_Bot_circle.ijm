/*  Syn_Bot
 *  Justin Savage
 *  3/17/21
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
analysisList = newArray("2 Channel Colocalization (RG)", "3 Channel Colocalization (RGB)");
threshTypes = newArray("Manual", "Fixed Value", "Percent Histogram", "FIJI auto","ilastik", "Pre-Thresholded");
roiList = newArray("Whole Image", "Auto Cell Body", "Circle", "custom");
Dialog.addRadioButtonGroup("Analysis Type", analysisList, 1, 2, "2 Channel Colocalization (RG)");
Dialog.addNumber("Red Min Pixel Size", 4);
Dialog.addNumber("Green Min Pixel Size", 4);
Dialog.addNumber("Blue Min Pixel Size", 4);
Dialog.addRadioButtonGroup("Thresholding", threshTypes, 2, 3, "Percent Histogram");
Dialog.addNumber("Red channel histogram percentage:", 2.5);
Dialog.addNumber("Green channel histogram percentage:", 2.0);
Dialog.addNumber("Blue channel histogram percentage:", 2.0);
Dialog.addRadioButtonGroup("ROI Type", roiList, 1, 4, "Whole Image");
Dialog.addCheckbox("Offset?", false);
Dialog.addCheckbox("Noise Reduction?", true);
Dialog.addCheckbox("Brightness Adjustment?", false);
Dialog.addCheckbox("Threshold From CSV File", false);
Dialog.show();
wizardString = Dialog.getRadioButton();
analysisType = Dialog.getRadioButton();
redMinPixel = Dialog.getNumber();
greenMinPixel = Dialog.getNumber();
blueMinPixel = Dialog.getNumber();
threshType = Dialog.getRadioButton();
redHisto = Dialog.getNumber();
greenHisto = Dialog.getNumber();
blueHisto = Dialog.getNumber();
roiType = Dialog.getRadioButton();
offsetBool = Dialog.getCheckbox();
noiseBool = Dialog.getCheckbox();
brightBool = Dialog.getCheckbox();
fromFileBool = Dialog.getCheckbox();


if(wizardString == "yes"){
	Dialog.create("Welcome");
	Dialog.addMessage("Welcome to Syn_Bot Macro. \n This macro uses ImageJ to calculate colocalizations between pre and postynaptic puncta in fluorescence microscopy images.");
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
		dirZ = dirSource + currentFile +"Z_projections"+File.separator;
		File.makeDirectory(dirZ);
		
		if (zProjectBool == true){
			//uses the projectPair function to Z-project images if necessary
			projectPair(dirSource + currentFile, dirZ);
			}
		if (zProjectBool == false){
			//uses the processCellImages function to convert in vitro images
			//to RGB
			print("dirSource + currentFile " + dirSource + currentFile);
			print("dirZ " + dirZ);
			processCellImages(dirSource + currentFile, dirZ);
			}

			
		//list of processed images in z_projects
		listZ = getFileList(dirZ);
		//for each image in dirZ
		for(i = 0; i < 1; i++){
			currentImage = listZ[i];
			//for each threshold offset in listOffset
			//the main analyzePuncta function is applied to each image
			print("dirZ is " + dirZ);
			print("dirZ + currentImage is " + dirZ + currentImage);

			//This is where the wizard should run to get the parameters
			dir1 = dirZ + currentImage;
			setBatchMode(false);
			run("Bio-Formats Importer", "open=["+dir1+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
			titleArray = split(dir1, "/");
			title = titleArray[titleArray.length-1];
			
			print("indexOf " + indexOf(title, "Z_projection"));
			
			titleTemp = title;
				
			if (indexOf(title, "Z_projections") >= 0){
				z = indexOf(title, "Z_projections");
				print("z is " + z);
				titleTemp = substring(title, z + 14, lengthOf(title));
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
			Dialog.addMessage("Displayed is the Red Channel of your first image. \n The first choice for the macro is whether this image needs the denoising features built in. \n The displayed image named noise_reduced has used our internal subtract background and gaussian blur. \n If this image doesn't look good, either use the raw image or complete your own denoising prior to using this macro. ");
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
			Dialog.addMessage("The Green Channel is now displayed. \n The macro uses the same mode (Manual, Fixed Value, Percent Histogram, FIJI auto, ilastik or Pre-Thresholded) \n for each channel but different parameters can be used. \n \n Click Ok to begin adjusting the threshold");
			Dialog.show();

			waitForUser("Adjust the threshold of the displayed image until you feel it correctly captures the desired puncta. \n Note either the threshold value or percent if you plan to use methods 2 or 3 \n You can try the automated FIJI methods using Image>Adjust>AutoThreshold \n and should note the name of the method that works best \n \n Click Ok when done");

			waitForUser("There are only a few other settings necessary for the macro. \n \n 1. Min Pixel Size: This denotes the smallest particle you wish to be counted \n as a true puncta. Examine your image and note the pixel size given when drawing an ROI \n around a typical puncta \n 2. ROI Type: Whole Image is used most often, but a circular ROI around a cell body or \n custom ROI around certain structures are also available. \n For further help and information see https://github.com/savagedude3/Coloc_Calculator \n \n Click Ok to begin the macro.");
			close("*");
			print("dirZ is: " + dirZ);
			listZ = getFileList(dirZ);
			for (i =0; i < listZ.length; i++){
				currentImage = listZ[i];
				File.delete(dirZ + currentImage);
				//print("deleting " + currentImage);
			}
			File.delete(dirZ);
		}
	}

	//Creates a dialog window for the user to input relevant parameters
	Dialog.create("Syn Bot");
	analysisList = newArray("2 Channel Colocalization (RG)", "3 Channel Colocalization (RGB)");
	threshTypes = newArray("Manual", "Fixed Value", "Percent Histogram", "FIJI auto","ilastik", "Pre-Thresholded");
	roiList = newArray("Whole Image", "Auto Cell Body", "Circle", "custom");
	Dialog.addRadioButtonGroup("Analysis Type", analysisList, 1, 2, "2 Channel Colocalization (RG)");
	Dialog.addNumber("Red Min Pixel Size", 4);
	Dialog.addNumber("Green Min Pixel Size", 4);
	Dialog.addNumber("Blue Min Pixel Size", 4);
	Dialog.addRadioButtonGroup("Thresholding", threshTypes, 2, 3, "Percent Histogram");
	Dialog.addNumber("Red channel histogram percentage:", 2.5);
	Dialog.addNumber("Green channel histogram percentage:", 2.0);
	Dialog.addNumber("Blue channel histogram percentage:", 2.0);
	Dialog.addRadioButtonGroup("ROI Type", roiList, 1, 4, "Whole Image");
	Dialog.addCheckbox("Offset?", false);
	Dialog.addCheckbox("Noise Reduction?", true);
	Dialog.addCheckbox("Brightness Adjustment?", false);
	Dialog.show();
	analysisType = Dialog.getRadioButton();
	redMinPixel = Dialog.getNumber();
	greenMinPixel = Dialog.getNumber();
	blueMinPixel = Dialog.getNumber();
	threshType = Dialog.getRadioButton();
	redHisto = Dialog.getNumber();
	greenHisto = Dialog.getNumber();
	blueHisto = Dialog.getNumber();
	roiType = Dialog.getRadioButton();
	offsetBool = Dialog.getCheckbox();
	noiseBool = Dialog.getCheckbox();
	brightBool = Dialog.getCheckbox();
}


//sets roi Radius
if(roiType == "Auto Cell Body" || roiType == "Circle"){
	Dialog.create("ROI Dimensions");
	Dialog.addNumber("ROI Radius", 301);
	Dialog.show();
	roiR = Dialog.getNumber();
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
	threshFile = File.openDialog("Choose Threshold File");
	Table.open(threshFile);
	redLowArray = Table.getColumn("Lower Red Threshold");
	redUpArray = Table.getColumn("Upper Red Threshold");
	greenLowArray = Table.getColumn("Lower Green Threshold");
	greenUpArray = Table.getColumn("Upper Green Threshold");
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
	Dialog.addNumber("Red Auto Constant", 0);
	Dialog.addNumber("Green Auto Constant", 0);
	Dialog.show();
	redTMethod = Dialog.getString();
	greenTMethod = Dialog.getString();
	blueTMethod = Dialog.getString();
	redAutoFactor = Dialog.getNumber();
	greenAutoFactor = Dialog.getNumber();
	redAutoConstant = Dialog.getNumber();
	greenAutoConstant = Dialog.getNumber();
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
if (threshType == "ilastik" && analysisType == "3 Channel Colocalization (RGB)"){
	ilpBlueDir = getDirectory("Choose ilp blue location");
}


//The following is the main chunk of the macro, which calls several
//helper functions that are defined below it

//Asks user for source directory (folder containing subfolder pairs)
print("Choose Source Directory");
dirSource  = getDirectory("Choose Source Directory ");
listSource = getFileList(dirSource);

startTime = getTime();

//arrays to store values for the summary ouput
imageList = newArray(10000);
redList = newArray(10000);
greenList = newArray(10000);
colocList = newArray(10000);
offsetUsed = newArray(10000);
lowerRedT = newArray(10000);
upperRedT = newArray(10000);
lowerGreenT = newArray(10000);
upperGreenT = newArray(10000);
imageScale = newArray(10000);
imageUnit = newArray(10000);
iterator = 0;

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

	//creates a subfolder for eah pair that will store the Z-projected, RGB
	//images and eventually all of the macro outputs
	dirZ = dirSource + currentFile +"Z_projections"+File.separator;
	File.makeDirectory(dirZ);

	if (zProjectBool == true){
		//uses the projectPair function to Z-project images if necessary
		projectPair(dirSource + currentFile, dirZ);
	}
	if (zProjectBool == false){
		//uses the processCellImages function to convert in vitro images
		//to RGB
		print("dirSource + currentFile " + dirSource + currentFile);
		print("dirZ " + dirZ);
		processCellImages(dirSource + currentFile, dirZ);
	}

	//list of processed images in z_projects
	listZ = getFileList(dirZ);
	//for each image in dirZ
	for(i = 0; i < listZ.length; i++){
		currentImage = listZ[i];
		//for each threshold offset in listOffset
		for(j = 0; j < listOffset.length; j++){
	
			k = j + (listOffset.length) * i;
			currentOffset = listOffset[j];
			//the main analyzePuncta function is applied to each image
			print("dirZ is " + dirZ);
			print("dirZ + currentImage is " + dirZ + currentImage);
			analyzePuncta(dirZ + currentImage, dirZ, currentOffset, redMinPixel, greenMinPixel, roiType, imageList, redList, greenList, colocList, offsetUsed, lowerRedT, upperRedT, lowerGreenT, upperGreenT, iterator, imageScale, imageUnit, ilpRedDir, ilpGreenDir);
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

redMinArray = newArray(iterator);
greenMinArray = newArray(iterator);

for(i = 0; i < iterator; i++){
	redMinArray[i] = redMinPixel;
	greenMinArray[i] = greenMinPixel;
}

Table.create("Summary");
Table.setColumn("Image", imageList);
Table.setColumn("Red Puncta Count", redList);
Table.setColumn("Green Puncta Count", greenList);
Table.setColumn("Colocalized Puncta Count", colocList);
Table.setColumn("Offset Used", offsetUsed);
Table.setColumn("Lower Red Threshold", lowerRedT);
Table.setColumn("Upper Red Threshold", upperRedT);
Table.setColumn("Lower Green Threshold", lowerGreenT);
Table.setColumn("Upper Green Threshold", upperGreenT);
Table.setColumn("Red Min Pixel", redMinArray);
Table.setColumn("Green Min Pixel", greenMinArray);
Table.setColumn("Scale", imageScale);
Table.setColumn("Unit", imageUnit);

Table.save(dirSource + "Summary.csv");

if (analysisType == "3 Channel Colocalization (RGB)"){
	//arrays to store values for the summary ouput
	imageList2 = newArray(10000);
	blueList = newArray(10000);
	colocListRtoB = newArray(10000);
	colocListGtoB = newArray(10000);
	colocListTriple = newArray(10000);
	lowerBlueT = newArray(10000);
	upperBlueT = newArray(10000);
	offsetUsed2 = newArray(10000);
	iterator2 = 0;

	if (roiType != "Auto Cell Body" || roiType != "Circle"){
		roiX = 0;
		roiY = 0;
		roiR = 0;
	}
	
	//for each pair m
	for(m = 0; m < listSource.length; m++){    
		currentFile = listSource[m];
		print("currentFile is: " + currentFile); 
		dirZ = dirSource + currentFile + File.separator + "Z_projections" + File.separator;
		print("dirZ is: " + dirZ);
		//list of processed images and data files in z_projects
		listZ = getFileList(dirZ);
		//for each file in dirZ
		for(i = 0; i < listZ.length; i++){
			currentImage = listZ[i];
			
			//for each threshold offset in listOffset
			for(j = 0; j < listOffset.length; j++){
		
				k = j + (listOffset.length) * i;
				currentOffset = listOffset[j];
				print("currentImage is: " + currentImage);
				feedbackBool = indexOf(currentImage, "coloc") >= 0; 
				if (endsWith(currentImage, ".tif") && !feedbackBool){
					//the thirdPuncta function is applied to each image
					thirdPuncta(dirZ + currentImage, dirZ, blueMinPixel, roiType, imageList2, blueList, colocListRtoB, colocListGtoB, colocListTriple, lowerBlueT, upperBlueT, iterator2, roiX, roiY, roiR, currentOffset, offsetUsed2, threshType, ilpBlueDir);
					//iterator is an iterator used to save the summary values
					//to the correct location
					iterator2 = iterator2 + 1;	
				}
			}
		}
	}


	blueMinArray = newArray(iterator2);
	
	for(i = 0; i < iterator2; i++){
		blueMinArray[i] = blueMinPixel;
	}

	imageList2 = Array.trim(imageList2, iterator2);
	blueList = Array.trim(blueList, iterator2);
	colocListRtoB = Array.trim(colocListRtoB, iterator2);
	colocListGtoB = Array.trim(colocListGtoB, iterator2);
	colocListTriple = Array.trim(colocListTriple, iterator2);
	offsetUsed2 = Array.trim(offsetUsed2, iterator2);
	lowerBlueT = Array.trim(lowerBlueT, iterator2);
	upperBlueT = Array.trim(upperBlueT, iterator2);
	blueMinArray = Array.trim(blueMinArray, iterator2);
	
	Table.create("Summary_2");
	
	Table.setColumn("Image", imageList2);
	Table.setColumn("Blue Puncta Count", blueList);
	Table.setColumn("Triple Colocalized Puncta Count", colocListTriple);
	Table.setColumn("Offset Used", offsetUsed2);
	Table.setColumn("Lower Blue Threshold", lowerBlueT);
	Table.setColumn("Upper Blue Threshold", upperBlueT);
	Table.setColumn("Blue Min Pixel", blueMinArray);
	
	Table.save(dirSource + "Summary_2.csv");
}

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

function analyzePuncta(dir1,dir2,currentOffset,redMinPixel, greenMinPixel, roiType, imageList, redList, greenList, colocList, offsetUsed, lowerRedT, upperRedT, lowerGreenT, upperGreenT, iterator, imageScale, imageUnit, ilpRedDir, ilpGreenDir){
	//batch mode hides images and makes the macro run faster
	setBatchMode(true);

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
	
	//opens the image, splits the channels and closes the blue channel
	open(dir1);

	print("dir1 is " + dir1);
	titleArray = split(dir1, "/");
	title = titleArray[titleArray.length-1];

	print("indexOf " + indexOf(title, "Z_projection"));

	titleTemp = title;
	
	if (indexOf(title, "Z_projections") >= 0){
		z = indexOf(title, "Z_projections");
		print("z is " + z);
		titleTemp = substring(title, z + 14, lengthOf(title));
	}
	
	print("title is " + title);
	run("Select All");
	
	getPixelSize(unit, pixelWidth, pixelHeight);
	 
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	run("Split Channels");
	//close blue
	close(title + " (blue)");
	
	//Analyze red puncta
	//The subtract background and Gaussian blur filters are applied 
	selectWindow(title + " (red)");
	splitName = split(titleTemp, ".");
	print("splitName is " + splitName[0]);
	run("Select All");
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
	}

	if (threshType == "Fixed Value"){
		setThreshold(setRedT, 255);
		getThreshold(lower, upper);
		redLower = lower;
		redUpper = upper;
	}

	if (threshType == "fromFile"){
		redLower = redLowArray[iterator];
		redUpper = redUpArray[iterator];
		setThreshold(redLower, redUpper);
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

		getThreshold(lower, upper);
		print(lower);
		redLower = lower;
		redUpper = upper;
		print("lower is " + lower);

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
	
	//runs Analyze Particles plugin using minPixel
	run("Analyze Particles...", "size=" + redMinPixel + "-Infinity pixel show=Overlay display exclude clear summarize add");
	close("Summary");


	print("before first save");
	print("splitName[0] " + splitName[0]);
	//saves all red puncta coordinates and area (and other stats) to
	//a csv file "redResults"
	print("save to " + dir2 + splitName[0] + "_redResults_" + toString(currentOffset) + ".csv");
	saveAs("Results", dir2 + splitName[0] + "_redResults_" + toString(currentOffset) + ".csv");

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
	}

	if (threshType == "Fixed Value"){
		setThreshold(setGreenT, 255);
		getThreshold(lower, upper);
		greenLower = lower;
		greenUpper = upper;
	}

	if (threshType == "fromFile"){
		greenLower = greenLowArray[iterator];
		greenUpper = greenUpArray[iterator];
		setThreshold(greenLower, greenUpper);
	}

	if (threshType == "FIJI auto"){
		run("Auto Threshold", "method=" + greenTMethod);
		getThreshold(lower, upper);

		//adjust lowerT
		lower = lower * greenAutoFactor + greenAutoConstant;

		
		setThreshold(lower, upper);
		greenLower = lower;
		greenUpper = upper;
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

		getThreshold(lower, upper);
		print(lower);
		greenLower = lower;
		greenUpper = upper;
		print("lower is " + lower);

		//setBatchMode("hide");
		
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
	
	//runs Analyze Particles plugin using minPixel
	run("Analyze Particles...", "size=" + greenMinPixel + "-Infinity pixel show=Overlay display exclude clear summarize add");
	close("Summary");

	//saves all green puncta coordinates and area (and other stats) to
	//a csv file "greenResults"
	saveAs("Results", dir2 + splitName[0] + "_greenResults_" + toString(currentOffset) + ".csv");

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

	//saves the output results table of Coloc_Calc, all the coloc puncta
	//coordinates, to a .csv file "colocResults"
	saveAs("Results", dir2 + splitName[0] + "_colocResults_" + toString(currentOffset) + ".csv");

	//stores the values from the Coloc_Calc plugin output Results table
	//as arrays
	selectWindow("Results");
	colocX = Table.getColumn("colocX");
	colocY = Table.getColumn("colocY");
	colocArea = Table.getColumn("colocArea");
	colocCount = colocX.length;

	//Enhance contrast to help visualize puncta in feedback image
	selectWindow(title + " (red)");
	run("Enhance Contrast", "saturated=1");
	selectWindow(title + " (green)");
	run("Enhance Contrast", "saturated=1");

	//merge the current image to produce the feedback image
	run("Merge Channels...", "c1=["+title+" (red)] c2=["+title+" (green)] create");
	
	run("Select None");
	print("colocCount is " + colocCount);

	//exits batch mode so that the puncta can be drawn correctly
	setBatchMode("show");
	setBatchMode(false);
	roiManager("reset");
	
	//draws each colocalized puncta onto the merged feedback image
	//by first adding each to the roi manager
	for(k = 0; k < colocCount; k++){
		makePoint(floor(colocX[k]),floor(colocY[k]),"dot white small"); 
		roiManager("Add");
		//roiManager("Select", k);
		//switched method and added if to try to fix the infrequent
		//error of no ROI selection
		RoiManager.select(k);
		if(roiManager("index")<k){
			print("switching to ROI " + k);
			RoiManager.select(k);
		}
		roiManager("Rename", "synapse "+ k +" ");
	}

	//the colocalized puncta in the roi manager are then drawn on the
	//feedback image if there are any
	if (colocCount != 0){
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
		Dialog.create("autoCellBody Error");
		Dialog.addMessage("Multiple Objects Detected");
		Dialog.addMessage("Switching to Circle ROI");
		beep();
		Dialog.show();
		return "error";
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
	run("Bio-Formats Importer", "open=["+dir1+file+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
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

//Runs the Z-Projection for all of the images in a file
function projectPair(dir1, dirZ) {

	list  = getFileList(dir1);
	setBatchMode(true);

	for (i = 0; i < (list.length - 1); i++) {
		print("i" + i + ":" + list[i]);
		if(endsWith(list[i], ".ini")){
			break;
		}
		zProject(dir1, dirZ, list[i]);
	}
}

//assumes C4 is red and C3 is green to convert single stack images 
//with more than 3 channels to RGB and save them in the Z_projects folder
function processCellImages(dir1, dirZ) {
	list1  = getFileList(dir1);

	for (i = 0; i < (list1.length - 1); i++) {
		redChannel = 99;
		greenChannel = 99;
		blueChannel = 99;
		setBatchMode(true);
		currentImage = list1[i];
		print("i" + i + ":" + list1[i]);
		if(endsWith(currentImage, ".ini")){
			print("ini found: " + currentImage);
			break;
		}
		open(dir1 + currentImage);
		getDimensions(width, height, channels, slices, frames);
		title = getTitle();
		//asks the user to select channels if there are more than 3 channels
		if (channels > 3 && redChannel == 99){
			run("Split Channels");
			setBatchMode("exit and display");
			Dialog.create("Channels to use");
			Dialog.addNumber("Red Channel:", 0);
			Dialog.addNumber("Green Channel:", 0);
			Dialog.addNumber("Blue Channel:", 0);
			Dialog.show();
			redChannel = Dialog.getNumber();
			greenChannel = Dialog.getNumber();
			run("Merge Channels...", "c1=[C"+redChannel+"-"+title+"] c2=[C"+greenChannel+"-"+title+"] c3=[C"+blueChannel+"-"+title+"] create");
			setBatchMode(true);
		}
		title = getTitle();
		selectWindow(title);
		run("RGB Color");
		saveAs(".tif", dirZ + File.separator +  currentImage);
		close("*");
	}
}

//Similar to analyze puncta but feeds blue channel puncta plus colocalzed puncta //from analyzePuncta into Coloc_Calc
function thirdPuncta(dir1, dir2, blueMinPixel, roiType, imageList2, blueList, colocList2, lowerBlueT, upperBlueT, iterator2, roiX, roiY, roiR, currentOffset, offsetUsed2, threshType, ilpBlueDir) {
	//batch mode hides images and makes the macro run faster
	setBatchMode(true);
	roiManager("reset");
	
	//opens the image, splits the channels and closes the blue channel
	open(dir1);
	title = getTitle();

	titleTemp = title;
	
	if (indexOf(title, "Z_projections") >= 0){
		z = indexOf(title, "Z_projections");
		print("z is " + z);
		titleTemp = substring(title, z + 14, lengthOf(title));
	}
	
	splitName = split(titleTemp, ".");
	run("Select All");
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	run("Split Channels");

	Table.open(dir2 + splitName[0] + "_redResults_" + currentOffset + ".csv");
	redX = Table.getColumn("X");
	redY = Table.getColumn("Y");
	redArea = Table.getColumn("Area");
	close(getInfo("window.title"));

	Table.open(dir2 + splitName[0] + "_greenResults_" + currentOffset + ".csv");
	greenX = Table.getColumn("X");
	greenY = Table.getColumn("Y");
	greenArea = Table.getColumn("Area");
	close(getInfo("window.title"));

	
	//Analyze blue puncta
	//The subtract background and Gaussian blur filters are applied 
	selectWindow(title + " (blue)");
	run("Select All");
	if(noiseBool == true){
		run("Subtract Background...", "rolling=50");
		//Nicola Allen's Lab uses the same Gaussian Blur
		//for their puncta analysis
		run("Gaussian Blur...", "sigma=0.57");
	}

	if (threshType == "Percent Histogram"){
		//Calculates histogram and then thresholds to image to 
		//include the top redHisto% of intensity values
		percentThreshold(blueHisto);
		//stores the lower threshold
		getThreshold(lower, upper);
		blueLower = lower;
		blueUpper = upper;
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
	}

	if (threshType == "Fixed Value"){
		setThreshold(setBlueT, 255);
		getThreshold(lower, upper);
		blueLower = lower;
		blueUpper = upper;
	}

	if (threshType == "FIJI auto"){
		run("Auto Threshold", "method=" + blueTMethod);
		getThreshold(lower, upper);
		setThreshold(lower, upper);
		blueLower = lower;
		blueUpper = upper;
	}

	if (threshType == "ilastik"){
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
		
		saveAs("Tiff", dir2 + splitName[0] + "ilastik_red");

		ilastikOutBlue = getTitle();

		File.delete(h5Path_in);
		File.delete(h5Path_out);
		
		run("8-bit");
		
		run("Auto Threshold", "method=Default white");

		getThreshold(lower, upper);
		print(lower);
		blueLower = lower;
		blueUpper = upper;
		print("lower is " + lower);

		//setBatchMode("hide");
		
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
		
	}

	//if roi was custom or Circle, loads the roi from the zip file
	if (roiType == "custom" || roiType == "Circle"){
		roiManager("open",dir2+splitName[0]+"_roi.zip");
		roiManager("select", 0);
		waitForUser("check roi");
	}
	//if roi was autoCellBody, makes an circle using the 
	//values calculated previously
	if (roiType == "Auto Cell Body"){
		makeOval(roiX - roiR, roiY - roiR, 2*roiR, 2*roiR);
	}
	
	//runs Analyze Particles plugin using minPixel
	run("Analyze Particles...", "size=" + blueMinPixel + "-Infinity pixel show=Overlay display exclude clear summarize add");
	
	close("Summary");

	//saves all green puncta coordinates and area (and other stats) to
	//a csv file "greenResults"
	saveAs("Results", dir2 + splitName[0] + "_blueResults.csv");

	//makes 3 arrays to store the x, y and radius values
	//of each green puncta (adapted from Richard Sriworarat)
	//the total number of red puncta 
	blueCount = getValue("results.count");
	//an array of all green puncta x values
	blueX = newArray(blueCount);
	//an array of all green puncta y values
	blueY = newArray(blueCount);
	//an array of all green puncta radius values
	blueR = newArray(blueCount);

	//calculates the radius of each puncta from the area and populates
	//the green arrrays with appropriate values
	for (i = 0; i < blueCount; i++) {
		blueX[i] = getResult("X", i);
		blueY[i] = getResult("Y", i);
		blueR[i] = sqrt(getResult("Area", i) / PI);
	}

	colocR = newArray(colocX.length);
	
	for (i = 0; i < colocX.length; i++) {
		colocR[i] = sqrt(colocArea[i] / PI);
		print("colocR is: " + colocR[i]);
	}

	close("Summary");
	close("Results");
	close("ROI Manager");

	//First calculate Red to Blue

	//creates a Results table that will be the input to the Coloc_Calc
	//plugin
	//treats red as red and blue as green inside the plugin
	Table.create("Results");
	Table.setColumn("redX", redX);
	Table.setColumn("redY", redY);
	Table.setColumn("redR", redR);
	Table.setColumn("greenX", blueX);
	Table.setColumn("greenY", blueY);
	Table.setColumn("greenR", blueR);

	
	//runs the Coloc_Calc plugin on the open "Results" window
	//the plugin will rename this to "oldResults" and 
	//display its output as a new "Results" table
	run("Syn_Bot_Helper");

	//stores the values from the Coloc_Calc plugin output Results table
	//as arrays
	selectWindow("Results");
	colocX2 = Table.getColumn("colocX");
	colocY2 = Table.getColumn("colocY");
	colocArea2 = Table.getColumn("colocArea");
	colocCountRtoB = colocX2.length;

	//saves the output results table of Coloc_Calc, all the coloc puncta
	//coordinates, to a .csv file "colocResults"
	saveAs("Results", dir2 + splitName[0] + "_colocResultsRtoB_" + toString(currentOffset) + ".csv");

	//Now calculate Green to Blue

	//creates a Results table that will be the input to the Coloc_Calc
	//plugin
	//treats green as red and blue as green inside the plugin
	Table.create("Results");
	Table.setColumn("redX", greenX);
	Table.setColumn("redY", greenY);
	Table.setColumn("redR", greenR);
	Table.setColumn("greenX", blueX);
	Table.setColumn("greenY", blueY);
	Table.setColumn("greenR", blueR);

	
	//runs the Coloc_Calc plugin on the open "Results" window
	//the plugin will rename this to "oldResults" and 
	//display its output as a new "Results" table
	run("Syn_Bot_Helper");

	//stores the values from the Coloc_Calc plugin output Results table
	//as arrays
	selectWindow("Results");
	colocX3 = Table.getColumn("colocX");
	colocY3 = Table.getColumn("colocY");
	colocArea3 = Table.getColumn("colocArea");
	colocCount3 = colocX3.length;

	//saves the output results table of Coloc_Calc, all the coloc puncta
	//coordinates, to a .csv file "colocResults"
	saveAs("Results", dir2 + splitName[0] + "_colocResultsGtoB_" + toString(currentOffset) + ".csv");

	//Now determine which colocs belong to RtoG (colocs from analyzePuncta), 
	//RtoB and RtoG

	//make a table with all of the coordinates to solve in Java

	Table.create("Results");
	Table.setColumn("redX", redX);
	Table.setColumn("redY", redY);
	Table.setColumn("redR", redR);
	Table.setColumn("greenX", blueX);
	Table.setColumn("greenY", blueY);
	Table.setColumn("greenR", blueR);

	//Enhance contrast to help visualize puncta in feedback image
	selectWindow(title + " (red)");
	run("Enhance Contrast", "saturated=1");
	selectWindow(title + " (green)");
	run("Enhance Contrast", "saturated=1");
	selectWindow(title + " (blue)");
	run("Enhance Contrast", "saturated=1");

	//merge the current image to produce the feedback image
	run("Merge Channels...", "c1=["+title+" (red)] c2=["+title+" (green)] c3=["+title+" (blue)] create");
	
	run("Select None");
	print("colocCount is " + colocCountRtoB);

	//exits batch mode so that the puncta can be drawn correctly
	setBatchMode("show");
	setBatchMode(false);
	roiManager("reset");
	
	//draws each colocalized puncta onto the merged feedback image
	//by first adding each to the roi manager
	for(k = 0; k < colocCountRtoB; k++){
		makePoint(colocX2[k],colocY2[k],"dot white small"); 
		roiManager("Add");
		roiManager("Select", k);
		roiManager("Rename", "synapse "+ k +" ");
	}

	//the colocalized puncta in the roi manager are then drawn on the
	//feedback image if there are any
	if (colocCountRtoB != 0){
		run("From ROI Manager");
	}	
	
	//Saves the feedback image showing colocalized puncta counted
	saveAs("tiff", dir2 + splitName[0] + "_colocs2");
	close("Results");
	close("oldResults");
	run("Close All");
	close("ROI Manager");

	imageList2[iterator2] = title;
	blueList[iterator2] = blueX.length;
	colocListRtoB[iterator2] = colocCountRtoB;
	colocListGtoB[iterator2] = colocCountGtoB;
	offsetUsed2[iterator2] = currentOffset;
	lowerBlueT[iterator2] = blueLower;
	upperBlueT[iterator2] = blueUpper;
	

	//end of thirdPuncta function
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
