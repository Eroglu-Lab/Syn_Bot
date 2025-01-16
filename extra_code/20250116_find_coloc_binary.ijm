//choose directory the SynBot Output directory
dir1 = getDir("choose SynBot Output directory");

list1 = getFileList(dir1);

list1_sorted = Array.sort(list1);

dirOut = dir1 + File.separator + "Masked_Images" + File.separator;

dirOut2 = dir1 + File.separator + "Blue_Masks" + File.separator;

File.makeDirectory(dirOut);

File.makeDirectory(dirOut2);

setBatchMode(true);


colocBinaryArray = newArray(10000);

//index for counted coloc_binary images
j = 0;

//print(list1_sorted.length);

//iterate through all files and find the coloc_binary images
for (i = 0; i < list1_sorted.length; i++) {
	currentFile = list1_sorted[i];
	currentImage = File.getNameWithoutExtension(dir1 + File.separator + currentFile);
	if(endsWith(currentImage, "_coloc_binary")){
		currentColocBinary = currentImage + ".tif";
		//print(currentColocBinary);
		colocBinaryArray[j] = currentColocBinary;
		j = j + 1;
	}
}

//print(j)

colocBinaryArray = Array.trim(colocBinaryArray, j);

rawImageArray = newArray(10000);

//iterate through the coloc_binary images and find the accompanying raw images
for (i = 0; i < colocBinaryArray.length; i++) {
	
	currentColocBinary = colocBinaryArray[i];
	//print(currentColocBinary);
	
	coloc_index = currentColocBinary.indexOf("_coloc_binary");
	
	//print(coloc_index);
	
	currentRawImage = substring(currentColocBinary, 0, coloc_index) + ".tif";
	
	//print(currentRawImage);
	
	rawImageArray[i] = currentRawImage;

}

//iterate through images and run blue channel mask

for (i = 0; i < colocBinaryArray.length; i++) {
	
	currentColocBinary = colocBinaryArray[i];
	currentRawImage = rawImageArray[i];
	
	print(currentColocBinary);
	print(currentRawImage);
	
	open(dir1 + File.separator + currentRawImage);
	
	currentTitle = getTitle();
	
	splitName = split(currentTitle, ".");
	
	run("Split Channels");
	
	//close red and green channels
//	selectWindow(currentTitle + " (red)");
//	close();
//	selectWindow(currentTitle + " (green)");
//	close();
	
	//open coloc_binary image
	open(dir1 + File.separator + currentColocBinary);
	currentColocTitle = getTitle();
	
	//select blue channel
	selectWindow(currentTitle + " (blue)");
	
	//threshold blue channel to 2% brightest pixels
	percentThreshold(2);
	
	run("Convert to Mask");
	run("Create Selection");
	
	//transfer the selection to the coloc_binary image
	selectImage(currentColocTitle);
	run("Restore Selection");
	
	//clear outside of selection
	run("Clear Outside");
	
	run("Select All");
	
	//run analyze particles
	run("Analyze Particles...", "size=0-Infinity pixel show=Overlay display exclude clear summarize add");

	//create a feedback image to see what was counted
	//clear the parts of coloc_binary that are outside of the mask
	selectImage(currentTitle + " (red)");
	run("Restore Selection");
	setBackgroundColor(0, 0, 0);
	run("Clear Outside");
	
	selectImage(currentTitle + " (green)");
	run("Restore Selection");
	run("Clear Outside");
	
	run("Merge Channels...", "c1=["+ currentTitle +" (red)] c2=["+ currentTitle +" (green)] create");
	
	run("From ROI Manager");
	
	saveAs("Tiff", dirOut + File.separator + splitName[0] + "_RG_masked.tif");
	
	close();

	
	//save blue channel mask
	selectImage(currentTitle + " (blue)");
	saveAs("Tiff", dirOut2 + File.separator + splitName[0] + "_blue_mask.tif");
	close();

	close("*");
}




/*function to threshold image to only include the top
n% of pixels in the intensity histogram based on: http://imagej.1557.x6.nabble.com/Threshold-as-a-percentage-of-image-histogram-td3695671.html
*/
function percentThreshold(percentIncluded){
	
	percentExcluded = 100 - percentIncluded;
	nBins = 256;
	getHistogram(values, count, nBins);
	size = count.length;
	// find culmulative sum
	totalPixels = getWidth() * getHeight();
	tissueValue = totalPixels * percentExcluded / 100;
	// cumulative sum of before
	cumSumValues = count;
	newLower = 0;
	for (i = 1; i<count.length; i++)
	{
	cumSumValues[i] += cumSumValues[i-1];
	}

	// find tissueValue
	for (i = 1; i<cumSumValues.length; i++)
	{
	if (cumSumValues[i-1] <= tissueValue && tissueValue <= cumSumValues[i]) {
	// output tissue threshold:
	newLower = i;
	//print("newLower is " + newLower);
		}
	}
	print("newLower is " + newLower);
	setThreshold(newLower,255);
}
