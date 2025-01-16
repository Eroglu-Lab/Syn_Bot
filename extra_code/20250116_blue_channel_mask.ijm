//choose directory the SynBot Output directory
dir1 = getDir("choose SynBot Output directory");

list1 = Arrays.sort(getFileList(dir1));



print(list1.length);

dirOut = dir1 + File.separator + "Masked_Images" + File.separator;

dirOut2 = dir1 + File.separator + "Blue_Masks" + File.separator;

File.makeDirectory(dirOut);

File.makeDirectory(dirOut2);

setBatchMode(true);


for (i = 0; i < list1.length; i++) {
	
	currentImage = list1[i];
	
	print(currentImage);
	
	open(dir1 + File.separator + currentImage);
	
	currentTitle = getTitle();
	
	splitName = split(currentTitle, ".");
	
	run("Split Channels");
	
	//threshold blue channel to 2% brightest pixels
	percentThreshold(2);
	
	run("Convert to Mask");
	run("Create Selection");
	//run("Restore Selection");
	
	//clear the parts of the red and green channels that are outside of the mask
	selectImage(currentTitle + " (red)");
	run("Restore Selection");
	setBackgroundColor(0, 0, 0);
	run("Clear Outside");
	
	selectImage(currentTitle + " (green)");
	run("Restore Selection");
	run("Clear Outside");
	
	run("Merge Channels...", "c1=["+ currentTitle +" (red)] c2=["+ currentTitle +" (green)] create");
	saveAs("Tiff", dirOut + File.separator + splitName[0] + "_RG_masked.tif");
	
	close();
	
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
