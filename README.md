# MOLT
Open source command line tool to facilitate re-skinning of animations made in Adobe After Effects.
MOLT does not provide an after effects license or renderer. You must purchase that separately.

MOLT runs through a folder of source files, and for each source file, renders an AE Composition that uses that source. 
Currently, MOLT only allows for the switching of a single source file, only supports Illustrator files as sources, and requires that all sources have the same layers.

# Project Setup
Use a working copy of your source with a Unique Name and place it in the same folder as the other sources that you intend to use. 
Set up a custom output module in your After Effects project (https://helpx.adobe.com/after-effects/using/basics-rendering-exporting.html)

You will need a reference to the directory that contains the after effects renderer in your PATH environment variable. https://helpx.adobe.com/after-effects/using/automated-rendering-network-rendering.html
# Usage
```powershell
molt -render
```
Render the after effects project according to the configuration in molt.config in the current folder

molt.config must contain the following 
