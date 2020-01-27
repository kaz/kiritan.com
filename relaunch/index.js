"use strict";

exports.run = async () => {
	const Compute = require("@google-cloud/compute");
	const compute = new Compute();
	const vm = await compute.zone(process.env.ZONE).vm(process.env.VM);

	console.log(await vm.start());
};
