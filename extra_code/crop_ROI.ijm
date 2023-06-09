dir1 = getDir("choose source directory");

list1 = getFileList(dir1);

dir2 = dir1 + File.separator + "cropped"

File.makeDirectory(dir2);

for (i = 0; i < list1.length; i++) {
	setBatchMode(true);
	currentImage = list1[i];
	open(dir1 + File.separator + currentImage);
	setTool("freehand");
	setBatchMode("exit and display");
	waitForUser("Draw freehand ROI around area to keep then click OK");
	roiManager("add");
	roiManager("save selected", dir2 + File.separator + File.getNameWithoutExtension(dir1 + File.separator + currentImage) + "_cropping.roi");
	setBatchMode("hide");
	run("Duplicate...", " ");
	run("Clear Outside");
	saveAs("Tiff", dir2 + File.separator + File.getNameWithoutExtension(dir1 + File.separator + currentImage) + "_cropped_inside.tif");
	close();
	run("Clear");
	saveAs("Tiff", dir2 + File.separator + File.getNameWithoutExtension(dir1 + File.separator + currentImage) + "_cropped_outside.tif");
	close();

}