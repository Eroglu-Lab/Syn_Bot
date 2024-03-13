//generates simulated images by creating a background image of gaussian noise and 
//then pasting on puncta from an image
//Sparse version generates 1/3 red only, 1/3 green only, and 1/3 red and green

//multiply noise by this to increase or decrease proportionally
//adds more or less background, 0 gives black background
noiseMultiplier = 0.50;
//get string of noiseMultiplier and replace the "." with "_". 
//Requires a number with digits before and after the decimal point
noiseArray = split(d2s(noiseMultiplier, 2),".");
noiseString = noiseArray[0] + "_" + noiseArray[1];

redMinPixel = 10;
redMaxString = 50;

greenMinPixel = 10;
greenMaxString = 50;

redThreshValue = 90;
greenThreshValue = 90;

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

dirRedThresh = dir1 + File.separator + "red_thresh";
File.makeDirectory(dirRedThresh);

dirGreenThresh = dir1 + File.separator + "green_thresh";
File.makeDirectory(dirGreenThresh);

dirRedBackground = dir1 + File.separator + "red_background";
File.makeDirectory(dirRedBackground);

dirGreenBackground = dir1 + File.separator + "green_background";
File.makeDirectory(dirGreenBackground);

dirOut = dir1 + File.separator + "output";
File.makeDirectory(dirOut);

dirImagej = getDirectory("imagej");





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
	
	imageWidth = width;
	imageHeight = height;
	
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

	//save the first 10 red puncta
	
	//save the puncta so we can find them again
	for ( ii= 0; ii < 10; ii++) {
	
		run("Duplicate...", " ");
		rename("current_puncta");
		roiManager("select", ii);
		run("Clear Outside");
		run("Crop");
		saveAs("tiff", dirImagej + File.separator + "red_puncta_" + ii);
		close();
		
	}
	
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

	//save the first 10 green puncta

	//save the puncta so we can find them again
	for ( ii= 0; ii < 10; ii++) {
	
		run("Duplicate...", " ");
		rename("current_puncta");
		roiManager("select", ii);
		run("Clear Outside");
		run("Crop");
		saveAs("tiff", dirImagej + File.separator + "green_puncta_" + ii);
		close();
	
	}
	
	close("*");
	roiManager("reset");
	
	//paste on fake synapses

	redBackgroundList = getFileList(dirRedBackground);

	imagejList = getFileList(dirImagej);
	
	redPunctaList = newArray(10);
	
	skipj = 0;
	skipk = 0;
	
	iterator = 0;
	
	//get list of just red_puncta images
	for (ii = 0; ii < imagejList.length; ii++) {

		currentFile = imagejList[ii];
		if(indexOf(currentFile, "red_puncta_") >= 0){
			redPunctaList[iterator] = currentFile;
			iterator = iterator + 1;
		}
	}
	
	open(dirRedBackground + File.separator + redBackgroundList[i]);
	title = getTitle();
	
	redCount = 0;
	
	jList = newArray(10000);
	
	redPrint = 1;
	
	redTruthFile = File.open(dirOut + File.separator + "red_truth.txt");
	
	
	for (m = 0; m < redPunctaList.length; m++) {
	
		
		
		open(dirImagej + File.separator + redPunctaList[m]);
		
		rename("current_puncta");
		
		getDimensions(punctaWidth, punctaHeight, channels, slices, frames);
		
		Image.copy;
		
		selectWindow(title);
		
		getDimensions(width, height, channels, slices, frames);
		
		//key for ground truth table
		//0 = no puncta
		//1 = puncta present
		
		
		
		//start loop at 20 so puncta aren't on the edge
		for (j = 20 + skipj; j < width; j = j + 100) {
			
			//print(j);
			
			//break out of loop if puncta to paste would go beyond the bounds of the image
			if(j + punctaWidth > width - 10){
					break;
				}
				
			//break if we already used this j for a different puncta
			if(jList[j] == 1){
				break;
			}
		
			for (k = 20 + skipk; k < height; k = k + 50) {
				
				//print(k);
				
				//break out of loop if puncta to paste would go beyond the bounds of the image
				if(k + punctaHeight > height - 10){
					break;
				}
				
				//paste red synapse 2/3 of the time on 1 and 2
				if(redPrint == 1){
					//waitForUser("check paste");
					Image.paste(j,k);
					redCount = redCount + 1;
					redPrint = 2;
					red_coord = toString(j) + "," + toString(k);
					print(redTruthFile, red_coord);
					continue;
				}
				
				if(redPrint == 2){
					//waitForUser("check paste");
					Image.paste(j,k);
					redCount = redCount + 1;
					redPrint = 3;
					red_coord = toString(j) + "," + toString(k);
					print(redTruthFile, red_coord);
					continue;
				}
				if(redPrint == 3){
					redPrint = 1;
					continue;
				}
			}
		
		//record which j was used
		jList[j] = 1;
		
		}
		
		
		
		skipj = skipj + 20;
		//skipk = skipk + 5;
		
		close("current_puncta");
		//delete the red puncta after we use it
		File.delete(dirImagej + File.separator + redPunctaList[m]);
		
	}
	
	selectWindow(title);
	redTitle = title;
	saveAs("tiff", dirOut + File.separator + title);
	
	close("*");
	
	print("redCount: " + redCount);
	
	File.close(redTruthFile);
	
	
	//paste on fake synapses

	greenBackgroundList = getFileList(dirGreenBackground);

	imagejList = getFileList(dirImagej);
	
	greenPunctaList = newArray(10);
	
	skipj = 0;
	skipk = 0;
	
	iterator = 0;
	
	//get list of just green_puncta images
	for (ii = 0; ii < imagejList.length; ii++) {

		currentFile = imagejList[ii];
		
		if(indexOf(currentFile, "green_puncta_") >= 0){
			greenPunctaList[iterator] = currentFile;
			iterator = iterator + 1;
		}
	}
	
	open(dirGreenBackground + File.separator + greenBackgroundList[i]);
	title = getTitle();
	
	greenCount = 0;
	jList = newArray(10000);
	greenPrint = 1;
	greenTruthFile = File.open(dirOut + File.separator + "green_truth.txt");
	
	for (m = 0; m < greenPunctaList.length; m++) {
	
		
		
		open(dirImagej + File.separator + greenPunctaList[m]);
		
		rename("current_puncta");
		
		getDimensions(punctaWidth, punctaHeight, channels, slices, frames);
		
		Image.copy;
		
		selectWindow(title);
		
		getDimensions(width, height, channels, slices, frames);
		

		
		//key for ground truth table
		//0 = no puncta
		//1 = puncta present
		
		//start loop at 20 so puncta aren't on edge
		for (j = 20 + skipj; j < width; j = j + 100) {
			
			//print(j);
			
			//break out of loop if puncta to paste would go beyond the bounds of the image
			if(j + punctaWidth > width - 10){
					break;
				}
				
			//break if we already used this j for a different puncta
			if(jList[j] == 1){
				break;
			}
		
			for (k = 20 + skipk; k < height; k = k + 50) {
				
				//print(k);
				
				//break out of loop if puncta to paste would go beyond the bounds of the image
				if(k + punctaHeight > height - 10){
					break;
				}
				
				//paste green synapse 2/3 of the time on 2 and 3
				if(greenPrint == 1){
					greenPrint = 2;
					continue;
				}
				
				if(greenPrint == 2){
					//waitForUser("check paste");
					Image.paste(j,k);
					greenCount = greenCount + 1;
					greenPrint = 3;
					green_coord = toString(j) + "," + toString(k);
					print(greenTruthFile, green_coord);
					continue;
				}
				if(greenPrint == 3){
					//waitForUser("check paste");
					Image.paste(j,k);
					greenCount = greenCount + 1;
					greenPrint = 1;
					green_coord = toString(j) + "," + toString(k);
					print(greenTruthFile, green_coord);
					continue;
				}

				
			}
			
			//record which j was used
			jList[j] = 1;
		
		}
		
		skipj = skipj + 20;
		//skipk = skipk + 5;
		
		close("current_puncta");
		
		//delete the green puncta after we use it
		File.delete(dirImagej + File.separator + greenPunctaList[m]);
		
	}
	
	print("greenCount: " + greenCount);
	
	open(dirOut + File.separator + redTitle);
	selectWindow(title);
	
	//run("Merge Channels...", "c1=Pair1_L2R2_7-9.tif_red_background.tif c2=Pair1_L2R2_7-9.tif_green_background.tif create");
	run("Merge Channels...", "c1="+ redTitle +" c2="+ title +" create");
	
	splitArray = split(title, ".");
	splitName = splitArray[0];
	
	saveAs("tiff", dirOut + File.separator + splitName + "_" + noiseString + ".tif");
	
	close("*");
	
	selectWindow("Summary");
	run("Close");
	selectWindow("Results");
	run("Close");
	selectWindow("ROI Manager");
	run("Close");
	
	
	File.close(greenTruthFile);
	


	
}
	

	




