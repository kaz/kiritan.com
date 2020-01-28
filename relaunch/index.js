"use strict";

const Compute = require("@google-cloud/compute");
const compute = new Compute();
const vm = compute.zone(process.env.ZONE).vm(process.env.VM);

exports.run = async () => {
	const [{status}] = await vm.getMetadata();
	if (status != "TERMINATED") {
		console.log(`status is now ${status}. retrying...`);
		await new Promise(resolve => setTimeout(resolve, 1000));
		return exports.run();
	}

	console.log(`status is now ${status}. relaunching instance...`);
	return vm.start();
};
