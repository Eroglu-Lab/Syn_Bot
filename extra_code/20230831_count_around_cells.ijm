/*
 * Preprocessing of images to convert from oir to tif and make channels red, green, and blue
 * 
 * open("C:/Users/savag/Desktop/soma_synapses/original_images/230712-AA150-Syt2488-NeuN647-Geph568-ACCL5-1.oir");
 * selectImage("230712-AA150-Syt2488-NeuN647-Geph568-ACCL5-1.oir");
 * run("Split Channels");
 * selectImage("C2-230712-AA150-Syt2488-NeuN647-Geph568-ACCL5-1.oir");
 * run("Merge Channels...", "c1=C2-230712-AA150-Syt2488-NeuN647-Geph568-ACCL5-1.oir c2=C1-230712-AA150-Syt2488-NeuN647-Geph568-ACCL5-1.oir c3=C3-230712-AA150-Syt2488-NeuN647-Geph568-ACCL5-1.oir create ignore");
 * saveAs("Tiff", "C:/Users/savag/Desktop/soma_synapses/tifs/230712-AA150-Syt2488-NeuN647-Geph568-ACCL5-1.tif");
 * selectImage("230712-AA150-Syt2488-NeuN647-Geph568-ACCL5-1.tif");
 * close(); 
*/


run("Set Measurements...", "area mean standard centroid center perimeter bounding shape integrated display redirect=None decimal=3");

dir1 = getDir("choose source directory");

dirOut = dir1 + File.separator + "Output" + File.separator;

File.makeDirectory(dirOut);

//Z-project images and store the projections in the Output folder
projectPair(dir1, dirOut);

//quit batch mode that zProject uses
setBatchMode("false");

list1 = getFileList(dirOut);

print(list1.length);


for (i = 0; i < list1.length; i++) {
	//setBatchMode(true);
	currentImage = list1[i];
	print("Current Image is: " + currentImage);
	open(dirOut + currentImage);
	
	//get the pixel size so that we will have it for converting later
	getPixelSize(unit, pixelWidth, pixelHeight);

	//do the analysis in pixel units
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

	title = getTitle();
	splitName = split(title, ".");
	run("Split Channels");
	selectWindow(title + " (blue)");
	run("Convert to Mask", "background=Dark calculate black");
	run("Despeckle");
	
	blueMinPixel = 500;
	redMinPixel = 4;
	redMaxString = "Infinity";
	greenMinPixel = 4;
	greenMaxString = "Infinity";
	
	
	//runs Analyze Particles plugin using blueMinPixel
	run("Analyze Particles...", "size=" + blueMinPixel + "-Infinity pixel show=Overlay display exclude clear summarize add");
	close("Summary");

	//create a new image with just the puncta from the rois, 
	//this gets rid of any small particles that can confuse pixel mode
	
	Stack.getDimensions(width, height, channels, slices, frames);
	if(indexOf(getInfo("os.name"), "Windows") >= 0){
		newImage("From_ROI", "8-bit black", width, height, 1);
		roiManager("Set Fill Color", "yellow");
		roiManager("fill");
		roiManager("Show All without labels");
		run("Flatten");
	}
	
	run("Convert to Mask");
	
	rename(splitName[0] + "_mask1.tif");
	
	run("Dilate");
	run("Dilate");
	run("Dilate");
	
	
	saveAs("tif", dirOut + splitName[0] + "_mask1.tif");
	
	//save cell rois so we can pull them back up
	roiPath = dirOut + splitName[0] + "_rois.zip";
	
	roiManager("save", roiPath);
	
	//save the results window so that we have the size info for each cell
	
	selectWindow("Results");
	resultsPath = dirOut + splitName[0] + "_results.csv";
	saveAs("Results", resultsPath);
	
	//make red thresholded image for synapse counting 
	
	selectWindow(title + " (red)");

	
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
	run("Convert to Mask");
	
	//open roiManager
	run("ROI Manager...");
	
	roiManager("reset");
	//runs Analyze Particles plugin using minPixel
	run("Analyze Particles...", "size=" + redMinPixel + "-" + redMaxString + " pixel show=Overlay display exclude clear summarize add");
	close("Summary");
	
	//waitForUser("after analyze particles");
	
	numRois = roiManager("count");
	
	print("numRois is: " + numRois);

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

	setThreshold(1, 255);
	run("Convert to Mask");
	close("red_thresholded");
	
	//TODO verify mac fix 
	if(indexOf(getInfo("os.name"), "Mac") >= 0){
		selectWindow("From_ROI");
	}
	else{selectWindow("From_ROI-1");}
	rename("red_thresholded");
	close("From_ROI");
	
	//waitForUser("After From ROI");
	
	//save the red thresholded image so we can recall it later
	redThreshPath = dirOut + splitName[0] + "_redThresholded.tiff";
	saveAs("tiff", redThreshPath);
	//saving changes the name, so I will change it back for simplicity
	rename("red_thresholded");
	
	

	//make green thresholded image for synapse counting 
	
	selectWindow(title + " (green)");

	
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
	run("Convert to Mask");
	
	//open roiManager
	run("ROI Manager...");
	
	roiManager("reset");
	//runs Analyze Particles plugin using minPixel
	run("Analyze Particles...", "size=" + greenMinPixel + "-" + greenMaxString + " pixel show=Overlay display exclude clear summarize add");
	close("Summary");
	
	//waitForUser("after analyze particles");
	
	numRois = roiManager("count");
	
	print("numRois is: " + numRois);

	//create a new image with just the green puncta from the rois, 
	//this gets rid of any small particles that can confuse pixel mode
	
	
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
	close("green_thresholded");
	
	//TODO verify mac fix 
	if(indexOf(getInfo("os.name"), "Mac") >= 0){
		selectWindow("From_ROI");
	}
	else{selectWindow("From_ROI-1");}
	rename("green_thresholded");
	close("From_ROI");
	
	//waitForUser("After From ROI");
	
	//save the green thresholded image so we can recall it later
	greenThreshPath = dirOut + splitName[0] + "_greenThresholded.tiff";
	saveAs("tiff", greenThreshPath);
	//saving changes the name, so I will change it back for simplicity
	rename("green_thresholded");
	
	//now calculate colocs
	
	imageCalculator("AND create", "red_thresholded", "green_thresholded");
	rename(title + "_colocs");

	
	//set colocMinPixel to 0, could be changed
	colocMinPixel = 0;
	//count colocs in AND image
	run("Analyze Particles...", "size=" + colocMinPixel + "-Infinity pixel show=Overlay display exclude clear summarize add");
	close("Summary");
	
	selectWindow(title + "_colocs");
	
	colocPath = dirOut + splitName[0] + "_coloc_binary.tif";
	
	saveAs("tiff", colocPath);
	
	close("*");
	
	//count red, green, and colocs for each cell
	
	//count red
	open(redThreshPath);
	roiManager("reset");
	open(roiPath);
	
		n = roiManager('count');
	for (j = 0; j < n; j++) {
    	roiManager('select', j);
    	//counts synapses in each ROI and adds them to the Summary results table
    	run("Analyze Particles...", "size=0-Infinity pixel show=Overlay display exclude clear summarize");
	}
	selectWindow("Summary");
	redCountArray = Table.getColumn("Count");
	
	//add the red counts to the original results file
	open(resultsPath);
	Table.setColumn("redPunctaCount", redCountArray);
	saveAs("Results", resultsPath);
	
	close("Summary");
	
	
	//count green
	open(greenThreshPath);
	roiManager("reset");
	open(roiPath);
	
		n = roiManager('count');
	for (j = 0; j < n; j++) {
    	roiManager('select', j);
    	//counts synapses in each ROI and adds them to the Summary results table
    	run("Analyze Particles...", "size=0-Infinity pixel show=Overlay display exclude clear summarize");
	}
	selectWindow("Summary");
	greenCountArray = Table.getColumn("Count");

	
	//add the green counts to the original results file
	open(resultsPath);
	Table.setColumn("greenPunctaCount", greenCountArray);
	saveAs("Results", resultsPath);
	
	/////////////////////
	//Still need to find a way to clear the Summary table before saving
	////////////////////
	
	close("Summary");
	
	
	//count colocs
	open(colocPath);
	roiManager("reset");
	open(roiPath);
	
		n = roiManager('count');
	for (j = 0; j < n; j++) {
    	roiManager('select', j);
    	//counts synapses in each ROI and adds them to the Summary results table
    	run("Analyze Particles...", "size=0-Infinity pixel show=Overlay display exclude clear summarize");
	}
	selectWindow("Summary");
	colocsCountArray = Table.getColumn("Count");

	
	//add the colocs counts to the original results file
	open(resultsPath);
	Table.setColumn("colocsPunctaCount", colocsCountArray);
	saveAs("Results", resultsPath);
	
	close("Summary");
	
	//close everything to clean up for the next image
	print("finished image: " + currentImage + " i " + i);
	close("*");
	close("Threshold");
	close("Results");
	close("ROI Manager");
	close(splitName[0] + "_results.csv");
		
}





//#########################
//helper functions
//#########################

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

	for (k = 0; k < list.length; k++) {
		print("k" + k + ":" + list[k]);
		if(endsWith(list[k], ".ini")){
			continue;
		}
		if(endsWith(list[k], "/")){
			continue;
		}
		if(endsWith(list[k], ".lif")){
			continue;
		}
		zProject(dir1, dirOut, list[k]);
	}
}

