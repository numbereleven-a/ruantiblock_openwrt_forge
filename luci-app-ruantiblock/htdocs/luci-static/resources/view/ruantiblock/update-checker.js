'use strict';
'require baseclass';
'require fs';

const UPDATE_CHECK_HELPER = '/usr/libexec/luci-app-ruantiblock/check-updates';
const UPDATE_CANCEL_HELPER = '/usr/libexec/luci-app-ruantiblock/cancel-update-check';
const RELEASE_URL = 'https://github.com/numbereleven-a/ruantiblock_openwrt_forge/releases/latest';

function parseVersion(value) {
	let raw = String(value || '').trim();
	let normalized = raw.replace(/^[vV]/, '');
	let match = normalized.match(/^(\d+(?:\.\d+)*)(?:-([0-9A-Za-z.-]+))?$/);

	if(!match) {
		return null;
	};

	let suffix = match[2] ? match[2].split('.') : [];
	let revision = null;
	if(suffix.length === 1 && /^r\d+$/i.test(suffix[0])) {
		revision = Number(suffix[0].slice(1));
		suffix = [];
	};

	return {
		raw       : raw,
		numbers   : match[1].split('.').map(Number),
		prerelease: suffix,
		revision  : revision,
	};
};

function comparePrereleaseIdentifiers(left, right) {
	let leftRevision = left.match(/^([A-Za-z]+)(\d+)$/);
	let rightRevision = right.match(/^([A-Za-z]+)(\d+)$/);

	if(leftRevision && rightRevision &&
		leftRevision[1].toLowerCase() === rightRevision[1].toLowerCase()) {
		return Number(leftRevision[2]) - Number(rightRevision[2]);
	};

	let leftNumeric = /^\d+$/.test(left);
	let rightNumeric = /^\d+$/.test(right);

	if(leftNumeric && rightNumeric) {
		return Number(left) - Number(right);
	};

	if(leftNumeric !== rightNumeric) {
		return leftNumeric ? -1 : 1;
	};

	return left.localeCompare(right);
};

function compareVersions(left, right) {
	let leftVersion = (typeof left === 'string') ? parseVersion(left) : left;
	let rightVersion = (typeof right === 'string') ? parseVersion(right) : right;

	if(!leftVersion || !rightVersion) {
		return null;
	};

	let length = Math.max(leftVersion.numbers.length, rightVersion.numbers.length);
	for(let i = 0; i < length; i++) {
		let result = (leftVersion.numbers[i] || 0) - (rightVersion.numbers[i] || 0);
		if(result !== 0) {
			return result;
		};
	};

	let leftPrerelease = leftVersion.prerelease;
	let rightPrerelease = rightVersion.prerelease;

	if(leftPrerelease.length === 0 && rightPrerelease.length === 0) {
		return (leftVersion.revision || 0) - (rightVersion.revision || 0);
	};
	if(leftPrerelease.length === 0) {
		return 1;
	};
	if(rightPrerelease.length === 0) {
		return -1;
	};

	length = Math.max(leftPrerelease.length, rightPrerelease.length);
	for(let i = 0; i < length; i++) {
		if(leftPrerelease[i] === undefined) {
			return -1;
		};
		if(rightPrerelease[i] === undefined) {
			return 1;
		};

		let result = comparePrereleaseIdentifiers(
			leftPrerelease[i], rightPrerelease[i]);
		if(result !== 0) {
			return result;
		};
	};

	return 0;
};

return baseclass.extend({
	__init__() {
		this.activeRequest = null;
	},

	cancel() {
		if(this.activeRequest) {
			this.activeRequest.cancelled = true;
			fs.exec(UPDATE_CANCEL_HELPER, []).catch(() => {});
			this.activeRequest = null;
		};
	},

	check(currentVersion) {
		this.cancel();

		let current = parseVersion(currentVersion);
		if(!current) {
			return Promise.reject(new Error('Invalid current version'));
		};

		let request = { cancelled: false };
		this.activeRequest = request;

		return fs.exec(UPDATE_CHECK_HELPER, []).then(result => {
			if(request.cancelled) {
				return { state: 'cancelled' };
			};
			if(!result || Number(result.code) !== 0) {
				throw new Error('Update check failed');
			};

			let latestVersion = String(result.stdout || '').trim();
			let latest = parseVersion(latestVersion);
			if(!latest || compareVersions(latest, current) === null) {
				throw new Error('Invalid release version');
			};

			return {
				state         : compareVersions(latest, current) > 0 ? 'update' : 'latest',
				currentVersion: current.raw,
				latestVersion : latest.raw,
				releaseUrl    : RELEASE_URL,
			};
		}).catch(error => {
			if(request.cancelled) {
				return { state: 'cancelled' };
			};
			throw error;
		}).finally(() => {
			if(this.activeRequest === request) {
				this.activeRequest = null;
			};
		});
	},
});
