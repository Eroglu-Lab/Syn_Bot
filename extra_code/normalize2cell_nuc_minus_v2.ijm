data_file = File.openDialog("Choose Summary.csv file");
Table.open(data_file);
selectWindow("Summary.csv");
colocArray = Table.getColumn("Colocalized Puncta Count");
numImgs = colocArray.length;
//print(numImgs);
areaArray = newArray(numImgs);

dir1 = getDir("Choose Output Directory");
list1 = getFileList(dir1);

imgNumber = 0;

setBatchMode(true);

for (i = 0; i < list1.length; i++) {
	
	currentFile = list1[i];
	
	//skip if file is anything but the Zprojected image
	
	if (endsWith(currentFile, "colocResults_0.csv")){
		continue;
	}
	
	if (endsWith(currentFile, "colocs.tif")){
		continue;
	}
	
	if (endsWith(currentFile, "coloc_binary.tif")){
		continue;
	}

	
	if (endsWith(currentFile, "colocResults_0.csv")){
		continue;
	}
	
	if (endsWith(currentFile, "redResults_0.csv")){
		continue;
	}
	
	if (endsWith(currentFile, "greenResults_0.csv")){
		continue;
	}

	
	if (endsWith(currentFile, "greenThresholded_0.tiff")){
		continue;
	}
	
	if (endsWith(currentFile, "redThresholded_0.tiff")){
		continue;
	}
	else{
		
		//open image and get area of the cropped astrocyte territory
		print(currentFile);
		open(dir1 + "/" + currentFile);
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
}

selectWindow("Summary.csv");
Table.setColumn("Territory Area", areaArray);

normRedArray = newArray(numImgs);
normGreenArray = newArray(numImgs);
normColocArray = newArray(numImgs);

for (i = 0; i < numImgs; i++) {
	
	normRedArray[i] = Table.get("Red Puncta Count", i) / Table.get("Territory Area", i);
	normGreenArray[i] = Table.get("Green Puncta Count", i) / Table.get("Territory Area", i);
	normColocArray[i] = Table.get("Colocalized Puncta Count", i) / Table.get("Territory Area", i);

}

Table.setColumn("Normalized Red Count", normRedArray);
Table.setColumn("Normalized Green Count", normGreenArray);
Table.setColumn("Normalized Coloc Count", normColocArray);

selectWindow("Summary.csv");
//data_file = File.openDialog("Choose Summary.csv file");

//TODO: outPath is just Summary_normalized.csv without full path
outPath = File.getParent(data_file) + "/" + File.getNameWithoutExtension(data_file) + "_normalized.csv";
print(outPath);

saveAs("Results", outPath);

close("Summary_normalized.csv");
close("Results");
close("Log");
