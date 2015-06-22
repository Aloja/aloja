# ALOJA Big Data benchmarking platform [![Build Status](https://travis-ci.org/Aloja/aloja.svg?branch=master)](https://travis-ci.org/Aloja/aloja)

###Quick start

1. Get familiar with the Web app, browse data and views at: [**http://hadoop.bsc.es**](http://hadoop.bsc.es)
2. Checkout some slides or publications as background and documentation: [http://hadoop.bsc.es/publications](http://hadoop.bsc.es/publications)

##### To experiment on a local DEV copy:

```bash
git clone https://github.com/Aloja/aloja.git
cd aloja
vagrant up
xdg-open http://localhost:8080
```
**Note:** Requires git, [vagrant >= v1.6](http://www.vagrantup.com), some patience to download and import the VM, and a web browser.

### About ALOJA

The [**ALOJA**](http://hadoop.bsc.es) research project is an initiative from the [Barcelona Supercomputing Center (BSC)]( http://www.bsc.es) to explore new hardware architectures for Big Data processing.  One of the main goals of the project is to produce a systematic study of SW and HW configuration and deployment options; where we are analyzing the cost-effectiveness of the different cloud services (*IaaS or PasS*) as well as on-premise hardware, both commodity and up-scale. 

In ALOJA we have currently created the largest vendor-neutral repository of Hadoop benchmark with over **42,000 public results**, as well as several tools for the management of the full-cycle from planning and execution of benchmarks, to data analysis and automated tools to produce insights to better understand system behavior and take decisions on framework and cluster design.

This repository includes the on-going open source tools of this project that consists of:
* Cluster definition and automated deployment
* Benchmark selection and iteration of configurations
* Metrics collections, results gathering, and importing into a DB
* Web application to manage results
* Advanced data views for aggregate results with filters
* Predictive Analytics (PA) aka Machine Learning tools for modeling and Knowledge Discovery

### More info
The project is under constant development and in the process of being documented. Feel free to browse the site, the code, and send inquiries, feature requests or bug reports to: 

**Write us at: [hadoop@bsc.es](mailto:hadoop@bsc.es)**
