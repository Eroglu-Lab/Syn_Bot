dir1 = getDir("choose source directory");
list1 = getFileList(dir1);
dirOut = getDir("choose destination directory");

setBatchMode(true);

for (i = 0; i < list1.length; i++) {
	currentImage = list1[i];
	open(dir1 + currentImage);
	run("Subtract Background...", "rolling=50");
	run("Gaussian Blur...", "sigma=0.57");
	saveAs("tiff", dirOut + File.separator + currentImage);
	close("*");
}

print("done");