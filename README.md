
This repo contains the key innovation to fix path-based knitr weirdness if rendering from different directories.

```r
    # add this to opts_chunk
    # it prevents knitr putting the wrong path in
    fig.process=normalizePath)      
```

[Here's the code](https://github.com/TomHarrop/labmeeting-20200416/blob/28d20787b7841fdb4817079f43f6effb50ab8046/style/r_setup.Rmd#L53)
