run("Set Measurements...", "area mean standard centroid center perimeter bounding shape integrated display redirect=None decimal=3");

dir1 = getDir("choose source directory"

list1 = getFileList(dir1);

dir2 = dir1 + File.separator + "masks"

File.makeDirectory(dir2);


for (i = 0; i < list1.length; i++) {
	//setBatchMode(true);
	currentImage = list1[i];
	open(dir1 + File.separator + currentImage);
	title = getTitle();
	splitName = split(title, ".");
	run("Split Channels");
	selectWindow("C3-" + title);
	run("Convert to Mask", "background=Dark calculate black");
	run("Despeckle");
	
	minPixel = 100;
	//runs Analyze Particles plugin using minPixel
	run("Analyze Particles...", "size=" + minPixel + "-Infinity pixel show=Overlay display exclude clear summarize add");
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
	//TODO: add pixel-based mode to count synapses in each ROI
	//Z-project the raw images so that you get 5 stacks for each image like SynBot
	//add columns to the results window for each ROI (cell) that include the red, green, and coloc counts
	
	
	setTool("freehand");
	//setBatchMode("exit and display");
	waitForUser("Draw freehand ROI around area to keep then click OK");
	roiManager("add");
	roiManager("save selected", dir2 + File.separator + File.getNameWithoutExtension(dir1 + File.separator + currentImage) + "_cropping.roi");
	//setBatchMode("hide");
	getDimensions(width, height, channels, slices, frames);
	if (slices == 1){
	//this Duplicate only works for single stacks
	run("Duplicate...", " ");
	}
	if (slices > 1){
	//this Duplicate works for z-stacks stacks
	run("Duplicate...", "duplicate");
	}
	run("Clear Outside");
	saveAs("Tiff", dir2 + File.separator + File.getNameWithoutExtension(dir1 + File.separator + currentImage) + "_cropped_inside.tif");
	close();
	run("Clear");
	saveAs("Tiff", dir2 + File.separator + File.getNameWithoutExtension(dir1 + File.separator + currentImage) + "_cropped_outside.tif");
	close();

}

close("*");