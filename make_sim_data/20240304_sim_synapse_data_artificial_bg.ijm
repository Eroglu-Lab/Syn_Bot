//generates simulated images by creating a background image of gaussian noise and 
//then pasting on puncta from an image

//open image
//split channgels
//open red thresholded
//threshold red thresholded and run analyze particles to add all to ROI manager
//select red channel on original image

dir1 = getDir("choose source folder");

dirRaw = dir1 + File.separator + "raw_images";
rawList = getFileList(dirRaw);

//dirRedThresh = dir1 + File.separator + "red_thresh";
//redThreshList = getFileList(dirRedThresh);
//
//dirGreenThresh = dir1 + File.separator + "green_thresh";
//greenThreshList = getFileList(dirGreenThresh);

dirRedThresh = dir1 + File.separator + "red_thresh"
File.makeDirectory(dirRedThresh);

dirGreenThresh = dir1 + File.separator + "green_thresh";
File.makeDirectory(dirGreenThresh);

dirRedBackground = dir1 + File.separator + "red_background";
File.makeDirectory(dirRedBackground);

dirGreenBackground = dir1 + File.separator + "green_background";
File.makeDirectory(dirGreenBackground);

dirOut = dir1 + File.separator + "output";
File.makeDirectory(dirOut);

redMinPixel = 10;
redMaxString = "Infinity"

greenMinPixel = 10;
greenMaxString = "Infinity"

redThreshValue = 90;
greenThreshValue = 90;

//multiply noise by this to increase or decrease proportionally
//adds more or less background, 0 gives black background
noiseMultiplier = 0.25;

for (i = 0; i < rawList.length; i++) {
	
	//open raw image and threshold each channel
	//threshold red channel
	open(dirRaw + File.separator + rawList[i]);
	title = getTitle();
	
	run("Split Channels");
	selectWindow(title + " (red)");
	
	setThreshold(redThreshValue, 255);
	run("Analyze Particles...", "size=" + 0 + "-" + "Infinity" + " pixel show=Overlay display clear summarize add");
	
	Stack.getDimensions(width, height, channels, slices, frames);
	
	if(indexOf(getInfo("os.name"), "Windows") >= 0){
		newImage("From_ROI", "8-bit black", width, height, 1);
		roiManager("Set Fill Color", "yellow");
		roiManager("fill");
		roiManager("Show All without labels");
		run("Flatten");
	}
	
	setThreshold(1, 255);
	run("Convert to Mask");
	
	//save the red thresholded image
	
	currentRedThresh = dirRedThresh + File.separator + title + "_red_threshold.tif";
	saveAs("tiff", currentRedThresh);

	
	//threshold green channel
	open(dirRaw + File.separator + rawList[i]);
	title = getTitle();
	
	run("Split Channels");
	selectWindow(title + " (green)");
	
	setThreshold(greenThreshValue, 255);
	run("Analyze Particles...", "size=" + 0 + "-" + "Infinity" + " pixel show=Overlay display clear summarize add");
	
	Stack.getDimensions(width, height, channels, slices, frames);
	
	if(indexOf(getInfo("os.name"), "Windows") >= 0){
		newImage("From_ROI", "8-bit black", width, height, 1);
		roiManager("Set Fill Color", "yellow");
		roiManager("fill");
		roiManager("Show All without labels");
		run("Flatten");
	}
	
	setThreshold(1, 255);
	run("Convert to Mask");
	
	//save the green thresholded image
	currentGreenThresh = dirGreenThresh + File.separator + title + "_green_threshold.tif";
	saveAs("tiff", currentGreenThresh);
	
	close("*");
	
	roiManager("reset");
	
	
	//generate red background image from histogram values of original image
	open(dirRaw + File.separator + rawList[i]);
	title = getTitle();
	
	run("Split Channels");
	selectWindow(title + " (red)");
	
	//create background image from image params
	Stack.getDimensions(width, height, channels, slices, frames);
	
	run("Clear Results");
	run("Measure");
	currentMean = getResult("Mean", 0) * noiseMultiplier;
	currentStd = getResult("StdDev", 0) * noiseMultiplier;
	
	//create 100x 100 pixel image
	newImage("red_background", "8-bit", width, height, 1);
	//fill image with pixel intensity of currentMean
	setColor(currentMean);
	fill();
	//add gaussian noise to image with standard deviation of currentStd
	run("Add Specified Noise...", "standard="+currentStd);
	
	saveAs("tiff", dirRedBackground + File.separator + title + "_red_background.tif");
	
	close("*");
	
	
	//get just larger ROIs for pasting artificial synapses
	roiManager("reset");
	
	open(currentRedThresh);
	title = getTitle();
	setThreshold(100, 255);
	run("Analyze Particles...", "size=" + redMinPixel + "-" + redMaxString + " pixel show=Overlay display exclude clear summarize add");
	
	close("*");
	
	
	open(dirRaw + File.separator + rawList[i]);
	title = getTitle();
	
	run("Split Channels");
	selectWindow(title + " (red)");
	
	dirRedPuncta = dir1 + "red_puncta_images/";
	File.makeDirectory(dirRedPuncta);
	print(dirRedPuncta);

	//save the first 10 red puncta

	roiManager("Select", newArray(0,1,2,3,4,5,6,7,8,9));
	RoiManager.multiCrop(dirRedPuncta, " save tif");
	
	close("*");
	roiManager("reset");

	//open image
	//split channels
	//open green thresholded
	//threshold green thresholded and run analyze particles to add all to ROI manager
	//select green channel on original image
	
	//generate red background image from histogram values of original image
	open(dirRaw + File.separator + rawList[i]);
	title = getTitle();
	
	run("Split Channels");
	selectWindow(title + " (green)");
	
	//create background image from image params
	Stack.getDimensions(width, height, channels, slices, frames);
	
	run("Clear Results");
	run("Measure");
	currentMean = getResult("Mean", 0) * noiseMultiplier;
	currentStd = getResult("StdDev", 0) * noiseMultiplier;
	
	//create 100x 100 pixel image
	newImage("green_background", "8-bit", width, height, 1);
	//fill image with pixel intensity of currentMean
	setColor(currentMean);
	fill();
	//add gaussian noise to image with standard deviation of currentStd
	run("Add Specified Noise...", "standard="+currentStd);
	
	saveAs("tiff", dirGreenBackground + File.separator + title + "_green_background.tif");
	
	close("*");
	
	//get just larger ROIs for pasting artificail synapses
	roiManager("reset");
	
	open(currentGreenThresh);
	title = getTitle();
	setThreshold(100, 255);
	run("Analyze Particles...", "size=" + greenMinPixel + "-" + greenMaxString + " pixel show=Overlay display exclude clear summarize add");
	
	close("*");
	
	open(dirRaw + File.separator + rawList[i]);
	title = getTitle();
	
	run("Split Channels");
	selectWindow(title + " (green)");
	
	dirGreenPuncta = dir1 + "green_puncta_images/";
	File.makeDirectory(dirGreenPuncta);
	print(dirGreenPuncta);

	//save the first 10 green puncta

	roiManager("Select", newArray(0,1,2,3,4,5,6,7,8,9));
	RoiManager.multiCrop(dirGreenPuncta, " save tif");
	
	close("*");
	roiManager("reset");
	
	//paste on fake synapses

	redPunctaList = getFileList(dirRedPuncta);
	
	skipj = 0;
	skipk = 0;
	
	//TODO: prevent pasting at the same place twice
	
	redBackgroundList = getFileList(dirRedBackground);
	
	open(dirRedBackground + File.separator + redBackgroundList[i]);
	title = getTitle();
	
	redCount = 0;
	
	jList = newArray(10000);
	
	for (m = 0; m < redPunctaList.length; m++) {
	
		
		
		open(dirRedPuncta + File.separator + redPunctaList[m]);
		
		rename("current_puncta");
		
		//clear outside to get only the puncta
		run("Clear Outside");
		
		getDimensions(punctaWidth, punctaHeight, channels, slices, frames);
		
		Image.copy;
		
		selectWindow(title);
		
		getDimensions(width, height, channels, slices, frames);
		
		//start loop at 20 so puncta aren't on the edge
		for (j = 20 + skipj; j < width; j = j + 100) {
			
			//print(j);
			
			//break out of loop if puncta to paste would go beyond the bounds of the image
			if(j + punctaWidth > width - 20){
					break;
				}
				
			//break if we already used this j for a different puncta
			if(jList[j] == 1){
				break;
			}
		
			for (k = 20 + skipk; k < height; k = k + 50) {
				
				//print(k);
				
				//break out of loop if puncta to paste would go beyond the bounds of the image
				if(k + punctaHeight > height - 20){
					break;
				}
				
				//waitForUser("check paste");
				Image.paste(j,k);
				
				redCount = redCount + 1;
				
			}
		
		//record which j was used
		jList[j] = 1;
		
		}
		
		
		
		skipj = skipj + 20;
		//skipk = skipk + 5;
		
		close("current_puncta");
		
	}
	
	selectWindow(title);
	redTitle = title;
	saveAs("tiff", dirOut + File.separator + title);
	
	close("*");
	
	print("redCount: " + redCount);
	
	
	//paste on fake synapses

	greenPunctaList = getFileList(dirGreenPuncta);
	
	skipj = 0;
	skipk = 0;
	
	greenBackgroundList = getFileList(dirGreenBackground);
	
	open(dirGreenBackground + File.separator + greenBackgroundList[i]);
	title = getTitle();
	
	greenCount = 0;
	jList = newArray(10000);
	
	for (m = 0; m < greenPunctaList.length; m++) {
	
		
		
		open(dirGreenPuncta + File.separator + greenPunctaList[m]);
		
		rename("current_puncta");
		
		//clear outside to get only the puncta
		run("Clear Outside");
		
		getDimensions(punctaWidth, punctaHeight, channels, slices, frames);
		
		Image.copy;
		
		selectWindow(title);
		
		getDimensions(width, height, channels, slices, frames);
		
		//start loop at 20 so puncta aren't on edge
		for (j = 20 + skipj; j < width; j = j + 100) {
			
			//print(j);
			
			//break out of loop if puncta to paste would go beyond the bounds of the image
			if(j + punctaWidth > width - 20){
					break;
				}
				
			//break if we already used this j for a different puncta
			if(jList[j] == 1){
				break;
			}
		
			for (k = 20 + skipk; k < height; k = k + 50) {
				
				//print(k);
				
				//break out of loop if puncta to paste would go beyond the bounds of the image
				if(k + punctaHeight > height - 20){
					break;
				}
				
				Image.paste(j,k);
				greenCount = greenCount + 1;
				
			}
			
			//record which j was used
			jList[j] = 1;
		
		}
		
		skipj = skipj + 20;
		//skipk = skipk + 5;
		
		close("current_");
		
	}
	
	print("greenCount: " + greenCount);
	
	open(dirOut + File.separator + redTitle);
	selectWindow(title);
	
	//run("Merge Channels...", "c1=Pair1_L2R2_7-9.tif_red_background.tif c2=Pair1_L2R2_7-9.tif_green_background.tif create");
	run("Merge Channels...", "c1="+ redTitle +" c2="+ title +" create");
	
	saveAs("tiff", dirOut + File.separator + redTitle);
	
	close("*");
	
	selectWindow("Summary");
	run("Close");
	selectWindow("Results");
	run("Close");
	selectWindow("ROI Manager");
	run("Close");
	
}
	

	




