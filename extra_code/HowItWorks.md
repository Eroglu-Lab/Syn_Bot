# Coloc_Calculator
## How It Works

## Coloc_Calculator Flow Chart

![Flow_Chart](https://github.com/savagedude3/Coloc_Calculator/blob/master/flow_chart.png)

## Why a macro and a plugin?

ImageJ macro language is a very easy way for anyone to quickly edit and run scripted actions on FIJI. The simplicity of the language combined with the macro recorder and large number of ready-to-use FIJI plugins make it a very attractive platform for open data science as anyone can adapt a macro to their particular data without much programming experience or development software. This accessibility is why the large majority of the Coloc_Calculator is written as an ImageJ macro. A major limitation of ImageJ macro language however is that it is quite slow when used to do computations directly. This is why the Coloc_Calc plugin (a java program that can run in FIJI) is used to determine the puncta colocalizations and calculate their area. 

## The Colocalization Calculation

The Coloc_Calc.jar plugin works by calculating the intersectional area of each puncta pair. The [Coloc_Calc.java](https://github.com/savagedude3/Coloc_Calculator/blob/master/Coloc_Calc.java) file is provided in this repo to show how this calculation is done and an online compiling version can be found [here](https://onlinegdb.com/S1HWVKUj8) for testing. The math for this calculation is based on the article [Calculate the intersection area of two circles](https://www.xarg.org/2016/07/calculate-the-intersection-area-of-two-circles/) by Robert Eisele. Since ImageJ plugins are usually void methods with few parameters, the macro displays the x and y coordinates and radius of each puncta for both channels in the "Results" table window and the plugin accesses the data from this table, changes its name to "oldResults" and displays the resulting colocalized puncta coordinates and area in a new "Results" window. 

## All puncta are approximated as circles

As the "Analyze Particles" function in FIJI measures the area of the puncta it counts and the calculation for colocalization can only be done this way with circular puncta, the area of each puncta is converted to a circular radius about the center coordinates recorded by "Analyze Particles" this approximation is quite accurate for our applications with typical synaptic markers, but may be inappropriate for some applications. ImageJ is capable of measuring [circularity](https://imagej.nih.gov/ij/plugins/circularity.html) so it may be helpful to check this for a few images before using the Coloc_Calculator for a new type of experiment.
