run("Set Measurements...", "area mean standard centroid center bounding shape integrated display redirect=None decimal=3");

dir1 = getDir("choose source directory");
list1 = getFileList(dir1);

setBatchMode(true);

Stack.getDimensions(width, height, channels, slices, frames);



if (


//for each image
for (i = 0; i < list1.length; i++) {
	currentImage = list1[i];
	run("Bio-Formats Importer", "open=["+dir1+currentImage+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	run("Split Channels");
	title = getTitle();
	
	rgbBool = checkRGB(dir1+currentImage);
	if(rgbBool == true){
		channels = 3;
	}
	
	//for each channel
	for (j = 0; j < channels; j++) {
		currentChannel = j;
		if(rgbBool == true){
			selectWindow(title + " (red)");
		}
		else{
			selectWindow("C1-" + title);
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
