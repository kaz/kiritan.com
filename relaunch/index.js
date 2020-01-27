"use strict";

const Compute = require("@google-cloud/compute");
const compute = new Compute();

exports.run = async () => console.log(await compute.zone(process.env.ZONE).vm(process.env.VM).start());
