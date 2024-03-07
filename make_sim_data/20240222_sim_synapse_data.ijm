//clear all above threshold areas from an image

//open image
//split channgels
//open red thresholded
//threshold red thresholded and run analyze particles to add all to ROI manager
//select red channel on original image

dir1 = getDir("choose source folder");

dirRaw = dir1 + File.separator + "raw_images";
rawList = getFileList(dirRaw);

dirRedThresh = dir1 + File.separator + "red_thresh";
redThreshList = getFileList(dirRedThresh);

dirGreenThresh = dir1 + File.separator + "green_thresh";
greenThreshList = getFileList(dirGreenThresh);

for (i = 0; i < rawList.length; i++) {
	open(redThreshList[i]);
	title = getTitle();
	setThreshold(100, 255);
	run("Analyze Particles...", "display clear summarize add");
	
	close("*");
	
	open(rawList[i]);
	title = getTitle();
	
	numROIs = roiManager("count");
	print("numROIs: " + numROIs);
	roiList = Array.getSequence(numROIs);

	for (i = 0; i < numROIs; i++) {
		roiManager("select", i);
		run("Clear");
	}
	
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
	
	open(greenThreshList[i]);
	title = getTitle();
	setThreshold(100, 255);
	run("Analyze Particles...", "display clear summarize add");
	
	close("*");
	
	open(rawList[i]);
	title = getTitle();
	
	numROIs = roiManager("count");
	print("numROIs: " + numROIs);
	roiList = Array.getSequence(numROIs);

	for (i = 0; i < numROIs; i++) {
		roiManager("select", i);
		run("Clear");
	}
	
	dirGreenPuncta = dir1 + "green_puncta_images/";
	File.makeDirectory(dirGreenPuncta);
	print(dirGreenPuncta);

	//save the first 10 green puncta

	roiManager("Select", newArray(0,1,2,3,4,5,6,7,8,9));
	RoiManager.multiCrop(dirGreenPuncta, " save tif");
	
	close("*");
	roiManager("reset");
	
}
	
	



//saveAs("tiff", dir1 + File.separator + title + "_red_background.tiff");

//open image
//split channgels
//open red thresholded
//threshold red thresholded and run analyze particles to add all to ROI manager
//select red channel on original image

dir1 = "C:/Users/savag/Desktop/make_sim_data/";
dir2 = dir1 + "red_puncta_images/";
File.makeDirectory(dir2);
print(dir2);

//save the first 10 red puncta

roiManager("Select", newArray(0,1,2,3,4,5,6,7,8,9));
RoiManager.multiCrop(dir2, " save tif");


//open image
//split channgels
//open red thresholded
//threshold red thresholded and run analyze particles to add all to ROI manager
//select red channel on original image

dir1 = "C:/Users/Justin/Desktop/make_sim_data/";
dir3 = dir1 + "green_puncta_images/";
File.makeDirectory(dir3);
//print(dir3);

//save the first 10 green puncta

roiManager("Select", newArray(0,1,2,3,4,5,6,7,8,9));
RoiManager.multiCrop(dir3, " save tif");


//paste on fake synapses

dir1 = "C:/Users/Justin/Desktop/make_sim_data/";
dir2 = dir1 + "red_puncta_images/";
list2 = getFileList(dir2);

skipj = 0;
skipk = 0;

for (i = 0; i < list2.length; i++) {
//for (i = 0; i < 1; i++) {

	open(dir2 + File.separator + list2[i]);
	
	rename("current_puncta");
	
	Image.copy;
	
	selectImage("Pair1_L2R2_7-9.tif (red)_red_background.tif");
	
	
	
	for (j = 0 + skipj; j < 1000; j = j + 60) {
		
		print(j);
	
		for (k = 0 + skipk; k < 1000; k = k + 20) {
			
			print(k);
			
			Image.paste(j,k);
			
		}
	
	}
	
	skipj = skipj + 5;
	//skipk = skipk + 5;
	
	close("current_puncta");
	
}


