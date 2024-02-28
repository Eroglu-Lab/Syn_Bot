//choose dir of cropped images
dir1 = getDir("Choose Output Directory");
list1 = getFileList(dir1);

areaArray = newArray(list1.length);

imgNumber = 0;

setBatchMode(true);

for (i = 0; i < list1.length; i++) {
	
	currentFile = list1[i];
	
	//open image and get area of the cropped astrocyte territory
	print(currentFile);
	open(dir1 + File.separator + currentFile);
	
	run("8-bit");
	setThreshold(1, 255, "raw");
	run("Analyze Particles...", "display clear summarize add");
	selectWindow("Results");
	currentArea = Table.get("Area", 0);
	print(currentArea);
	
	//add this area to the array and incremenet the imgNumber
	areaArray[imgNumber] = currentArea;
	imgNumber += 1;
	
	close("Resulst");
	close("Summary");
	close("*");

}

Table.create("cell_areas.csv");

Table.setColumn("Territory Area", areaArray);

Table.save(dir1 + File.separator + "cell_areas.csv");
