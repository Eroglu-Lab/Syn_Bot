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

//dilateNum = getNumber("How many dilations?", 5);


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
	
	run("Auto Threshold", "method=Default white");
	getThreshold(lower, upper);
	setThreshold(lower, upper);
	
	
	run("Despeckle");
	
	
	//fix images if they get inverted for some reason
	//if (is("Inverting LUT")){
	//	print("inverted LUT detected");
	//	run("Invert LUT");
	//	run("Invert");
	//}
	
	blueMinPixel = 10000;
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
	
	//run dilate dilateNum times to make the cell ROI that many pixels larger
	//for (l = 0; l < dilateNum; l++) {
	//	run("Dilate");
	//}
	
	roiManager("reset");
	
	run("Analyze Particles...", "size=" + blueMinPixel + "-Infinity pixel show=Overlay display exclude clear summarize add");
	close("Summary");

	
	saveAs("tif", dirOut + splitName[0] + "_mask1.tif");
	
	//save cell rois so we can pull them back up
	roiPath = dirOut + splitName[0] + "_rois.zip";
	
	roiManager("save", roiPath);
	
	//save the results window so that we have the size info for each cell
	
	selectWindow("Results");
	resultsPath = dirOut + splitName[0] + "_results.csv";
	saveAs("Results", resultsPath);
	
	
	//clear nuclear signal from red channel
	
	selectWindow(title + " (red)");
	
	roiManager("reset");
	
	open(roiPath);
	
	roiManager("Select", 0);
	run("Clear");
	
	//clear nuclear signal from green channel
	
	selectWindow(title + " (green)");
	
	roiManager("reset");
	
	open(roiPath);
	
	roiManager("Select", 0);
	run("Clear");
	
	run("Merge Channels...", "c1=["+title+" (red)] c2=["+title+" (green)] c3=["+title+" (blue)] create");

	saveAs("tiff", dirOut + splitName[0] + "_nuc_cleared.tiff");
	
	close("*");
		
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

