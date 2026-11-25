'use strict';
'require fs';
'require poll';
'require ui';
'require view';
'require view.ruantiblock.tools as tools';

document.head.append(E('style', {'type': 'text/css'},
`
.log-entries-count {
	margin: 0 0 5px 5px;
	font-weight: bold;
	opacity: 0.7;
}
`));

return view.extend({
	pollInterval   : L.env.pollinterval,

	escapeHtml(str) {
		return String(str).replace(/&/g, '&#38;').replace(/</g, '&#60;')
			.replace(/>/g, '&#62;').replace(/"/g, '&#34;').replace(/'/g, '&#39;');
	},

	secToTimeString(value) {
		let string = '';
		if(/^\d+$/.test(value)) {
			value = Number(value);
			let hours = 0, mins = 0, sec = 0, rest = value;
			if(value >= 3600) {
				hours = Math.floor(value / 3600);
				rest  = value % 3600;
			};
			if(rest >= 60) {
				mins = Math.floor(rest / 60);
				rest = rest % 60;
			};
			sec = rest;
			if(hours > 0) {
				string = string + hours + _('h');
			};
			if(mins > 0) {
				string = string + ' ' + mins + _('m');
			};
			string = string + ' ' + sec + _('s');
		};
		return string;
	},

	formatNftJson(data) {
		let output = { 'rules': [] };
		if(!data || typeof(data) !== 'object') {
			return output;
		};

		let rules = (data.rules && typeof(data.rules) === 'object') ? data.rules : {};

		function parseDnsmasqData(set) {
			let sArray = [];
			if(set && Array.isArray(set.nftables) && set.nftables.length > 1) {
				set.nftables.forEach(e => {
					if(e && e.set && Array.isArray(e.set.elem)) {
						e.set.elem.forEach(i => {
							if(i && i.elem) {
								sArray.push([ i.elem.val, i.elem.expires ]);
							};
						});
					};
				});
			};
			return sArray;
		};

		if(Array.isArray(rules.nftables) && rules.nftables.length > 1) {
			for(let i of rules.nftables) {
				if(!i || !i.rule) {
					continue;
				};
				let set, bytes, proto;
				if(Array.isArray(i.rule.expr)) {
					i.rule.expr.forEach(e => {
						if(!e) return;
						if(e.match && e.match.left) {
							if(e.match.left.payload &&
								(!e.match.left.payload.field || e.match.left.payload.field === 'daddr') &&
								typeof(e.match.right) === 'string') {
								set = e.match.right.replace('@', '');
							}
							else if(e.match.left.meta && e.match.left.meta.key === 'l4proto' &&
								typeof(e.match.right) === 'string') {
								proto = e.match.right;
							};
						}
						else if(e.counter) {
							bytes = e.counter.bytes;
						};
					});
				};
				output.rules.push(proto ? [ set, bytes, proto ] : [ set, bytes ]);
			};

		};

		if(data.dnsmasq) {
			output.dnsmasq = parseDnsmasqData(data.dnsmasq);
		};
		if(data.dnsmasq_bypass) {
			output.dnsmasq_bypass = parseDnsmasqData(data.dnsmasq_bypass);
		};
		if(Array.isArray(data.dnsmasq_user_instances)) {
			output.dnsmasq_user_instances = [];
			for(let i of data.dnsmasq_user_instances) {
				if(i && Array.isArray(i.nftables)) {
					let name;
					i.nftables.forEach(e => {
						if(e && e.set) {
							name = e.set.name;
						};
					});
					output.dnsmasq_user_instances.push([ name, parseDnsmasqData(i) ]);
				};
			};
		};

		return output;
	},

	makeDnsmasqTable(ipDataArray, title) {
		let lines   = `<tr class="tr"><td class="td center">${_('No entries available...')}</td></tr>`;
		let ipTable = E('table', { 'class': 'table ruantiblock-ip-table' });

		let entries = Array.isArray(ipDataArray) ? ipDataArray.filter(e => Array.isArray(e) && e.length >= 2) : [];
		entries.sort((a, b) => a[1] - b[1]);

		if(entries.length > 0) {
			lines = [];
			entries.forEach((e, i) => {
				if(e) {
					lines.push(
						`<tr class="tr"><td class="td left" data-title="${_('IP address')}">${this.escapeHtml(e[0])}</td>` +
						`<td class="td left" data-title="${_('Timeout')}">${this.secToTimeString(e[1] | 0)}</td></tr>`
					);
				};
			});
			lines = lines.join('');

			ipTable.append(
				E('tr', { 'class': 'tr table-titles' }, [
					E('th', { 'class': 'th left', 'style': 'width:33%' }, _('IP address')),
					E('th', { 'class': 'th left' }, _('Timeout')),
				])
			);
		};

		try {
			ipTable.insertAdjacentHTML('beforeend', lines);
		} catch(e) {
			if(e.name === 'SyntaxError') {
				ui.addNotification(null,
					E('p', {}, _('HTML/XML error') + ': ' + e.message), 'error');
			};
			throw e;
		};

		return E([
			E('h3', {}, title),
			E('div', { 'class': 'log-entries-count' },
				`${_('Entries')}: ${entries.length}`
			),
			ipTable,
		]);
	},

	makeUpdateStatusTable(data) {
		let update_status = E('table', { 'class': 'table' });
		if(data.last_blacklist_update && data.last_blacklist_update.status) {
			update_status.append(
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left', 'style': 'width:33%' },
						_('Last blacklist update') + ':'),
					E('td', { 'class': 'td left',
								'id' : 'last_blacklist_update.date' },
						data.last_blacklist_update.date),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, 'CIDR:'),
					E('td', { 'class': 'td left',
								'id' : 'last_blacklist_update.cidr' },
						data.last_blacklist_update.cidr),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, 'IP:'),
					E('td', { 'class': 'td left',
								'id' : 'last_blacklist_update.ip' },
						data.last_blacklist_update.ip),
				]),
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left' }, 'FQDN:'),
					E('td', { 'class': 'td left',
								'id' : 'last_blacklist_update.fqdn' },
						data.last_blacklist_update.fqdn),
				])
			);
		} else {
			update_status.append(
				E('tr', { 'class': 'tr' }, [
					E('td', { 'class': 'td left', 'style': 'width:33%' },
						_('Last blacklist update') + ':'),
					E('td', { 'class': 'td left',
								'id' : 'last_blacklist_update.date' }, _('No data')),
				])
			);
		};
		return update_status;
	},

	buildContentSections(data) {
		let update_status        = null,
			user_entries         = null,
			rules                = null,
			dnsmasq              = null,
			dnsmasqUserInstances = null,
			dnsmasqBypass        = null;

		if(data) {
			if(data.status === 'enabled') {
				update_status = this.makeUpdateStatusTable(data);

				if(Array.isArray(data.user_entries) && data.user_entries.length > 0) {
					user_entries = E('table', { 'class': 'table' });
					for(let i of data.user_entries) {
						if(!i || typeof i.id !== 'string') continue;
						user_entries.append(
							E('tr', { 'class': 'tr' }, [
								E('td', { 'class': 'td left', 'style': 'word-wrap:break-word' },
									i.id.slice(0, 114) + (i.id.length > 115 ? '...' : '')),
								E('td', { 'class': 'td left' },
									`CIDR: ${i.cidr}, IP: ${i.ip}, FQDN: ${i.fqdn}`),
							])
						);
					};
				};

				let nft_data = this.formatNftJson(data);

				if(nft_data.rules) {
					let table_rules = E('table', { 'class': 'table' }, [
						E('tr', { 'class': 'tr table-titles' }, [
							E('th', { 'class': 'th left', 'style': 'width:33%' },
								_('Match-set')),
							E('th', { 'class': 'th left' }, _('Description')),
							E('th', { 'class': 'th left' }, _('Bytes')),
						]),
					]);

					for(let [set, bytes, proto] of nft_data.rules) {
						if(!set) {
							continue;
						};
						table_rules.append(
							E('tr', { 'class': 'tr' }, [
								E('td',{
									'class'     : 'td left',
									'data-title': _('Match-set'),
								}, set),
								E('td', {
									'class'     : 'td left',
									'data-title': _('Description'),
								}, this.formatRuleDescription(set, proto)),
								E('td', {
									'class'     : 'td left',
									'id'        : this.ruleElementId(set, proto),
									'data-title': _('Bytes'),
								}, bytes),
							])
						);
					};

					rules = E([
						E('h3', {}, _('Nftables rules')),
						table_rules,
					]);
				};

				if(nft_data.dnsmasq) {
					dnsmasq = E('div', {
						'id'   : 'rdTableWrapper',
						'style': 'width:100%',
					}, this.makeDnsmasqTable(nft_data.dnsmasq, _('Dnsmasq')));
				};

				if(nft_data.dnsmasq_user_instances && nft_data.dnsmasq_user_instances.length > 0) {
					let rdsTableWrapper = E('div', {
						'id'   : 'rdsTableWrapper',
						'style': 'width:100%',
					});

					for(let i of nft_data.dnsmasq_user_instances) {
						rdsTableWrapper.append(this.makeDnsmasqTable(i[1], _('Dnsmasq') + ' ' + i[0]));
					};

					dnsmasqUserInstances = rdsTableWrapper;
				};

				if(nft_data.dnsmasq_bypass) {
					dnsmasqBypass = E('div', {
						'id'   : 'rdbTableWrapper',
						'style': 'width:100%',
					}, this.makeDnsmasqTable(nft_data.dnsmasq_bypass, _('Dnsmasq bypass')));
				};
			} else {
				update_status = E('em', {}, _('Status') + ' : ' + _('disabled'));
			};
		};

		let sections = [
			E('div', { 'class': 'cbi-section fade-in' },
				E('div', { 'id': 'updateStatusWrapper', 'class': 'cbi-section-node' }, update_status)
			),
		];

		if(user_entries) {
			sections.push(
				E('div', { 'class': 'cbi-section fade-in' }, [
					E('h3', {}, _('User entries')),
					E('div', { 'class': 'cbi-section-node' }, user_entries),
				])
			);
		};

		if(rules) {
			sections.push(
				E('div', { 'class': 'cbi-section fade-in' },
					E('div', { 'class': 'cbi-section-node' }, rules)
				)
			);
		};

		if(dnsmasqBypass) {
			sections.push(
				E('div', { 'class': 'cbi-section fade-in' },
					E('div', { 'class': 'cbi-section-node' }, dnsmasqBypass)
				)
			);
		};

		if(dnsmasqUserInstances) {
			sections.push(
				E('div', { 'class': 'cbi-section fade-in' },
					E('div', { 'class': 'cbi-section-node' }, dnsmasqUserInstances)
				)
			);
		};

		if(dnsmasq) {
			sections.push(
				E('div', { 'class': 'cbi-section fade-in' },
					E('div', { 'class': 'cbi-section-node' }, dnsmasq)
				)
			);
		};

		return sections;
	},

	makeLayoutSignature(data, nft_data) {
		let status = (data && data.status === 'enabled') ? 'enabled' : 'disabled';
		if(status !== 'enabled') {
			return status;
		};
		let ruleKeys = (nft_data.rules || [])
			.filter(r => r && r[0])
			.map(r => this.ruleElementId(r[0], r[2]))
			.join('|');
		let userEntriesKey = Array.isArray(data.user_entries)
			? data.user_entries.map(i => (i && typeof(i.id) === 'string')
				? `${i.id}:${i.cidr}:${i.ip}:${i.fqdn}` : '').join('|')
			: '';
		let flags = [
			nft_data.dnsmasq ? '1' : '0',
			(nft_data.dnsmasq_user_instances && nft_data.dnsmasq_user_instances.length > 0) ? '1' : '0',
			nft_data.dnsmasq_bypass ? '1' : '0',
		].join('');
		return `${status}#${flags}#${ruleKeys}#${userEntriesKey}`;
	},

	pollInfo() {
		return fs.exec_direct(tools.execPath, [ 'html-info' ], 'json').catch(e => {
			if(!this.pollErrorShown) {
				ui.addNotification(null, E('p', _('Unable to execute or read contents')
					+ ': %s [ %s ]'.format(e.message, tools.execPath)
				));
				this.pollErrorShown = true;
			};
		}).then(data => {
			if(!data) {
				return;
			};

			try {
				data = JSON.parse(data);
			} catch(e) {};
			this.pollErrorShown = false;

			let statsContentWrapper = document.getElementById('statsContentWrapper');
			let nextStatus = (data && data.status === 'enabled') ? 'enabled' : 'disabled';
			let nft_data = (nextStatus === 'enabled') ? this.formatNftJson(data) : null;
			let nextSignature = this.makeLayoutSignature(data, nft_data || {});

			if(statsContentWrapper && this.lastLayoutSignature !== nextSignature) {
				statsContentWrapper.innerHTML = '';
				this.buildContentSections(data).forEach(section => statsContentWrapper.append(section));
				this.lastLayoutSignature = nextSignature;
				return;
			};

			if(nextStatus === 'enabled') {
				let updateStatusWrapper = document.getElementById('updateStatusWrapper');
				if(updateStatusWrapper) {
					updateStatusWrapper.innerHTML = '';
					updateStatusWrapper.append(this.makeUpdateStatusTable(data));
				} else {
					let date = document.getElementById('last_blacklist_update.date');
					if(data.last_blacklist_update && data.last_blacklist_update.status) {
						if(date) {
							date.textContent = data.last_blacklist_update.date;
						};
						let ip   = document.getElementById('last_blacklist_update.ip');
						if(ip) {
							ip.textContent = data.last_blacklist_update.ip;
						};
						let cidr = document.getElementById('last_blacklist_update.cidr');
						if(cidr) {
							cidr.textContent = data.last_blacklist_update.cidr;
						};
						let fqdn = document.getElementById('last_blacklist_update.fqdn');
						if(fqdn) {
							fqdn.textContent = data.last_blacklist_update.fqdn;
						};
					} else if(date) {
						date.textContent = _('No data');
					};
				};

				if(nft_data.rules.length > 0) {
					for(let [set, bytes, proto] of nft_data.rules) {
						let elem = document.getElementById(this.ruleElementId(set, proto));
						if(elem) {
							elem.textContent = bytes;
						};
					};
				};

				let rdTableWrapper = document.getElementById('rdTableWrapper');
				if(rdTableWrapper) {
					rdTableWrapper.innerHTML = '';
					rdTableWrapper.append(this.makeDnsmasqTable(nft_data.dnsmasq || [], _('Dnsmasq')));
				};

				let rdsTableWrapper = document.getElementById('rdsTableWrapper');
				if(rdsTableWrapper) {
					rdsTableWrapper.innerHTML = '';
					for(let i of (nft_data.dnsmasq_user_instances || [])) {
						rdsTableWrapper.append(this.makeDnsmasqTable(i[1], _('Dnsmasq') + ' ' + i[0]));
					};
				};
				let rdbTableWrapper = document.getElementById('rdbTableWrapper');
				if(rdbTableWrapper) {
					rdbTableWrapper.innerHTML = '';
					rdbTableWrapper.append(this.makeDnsmasqTable(nft_data.dnsmasq_bypass || [], _('Dnsmasq bypass')));
				};
			};
		});
	},

	ruleElementId(set, proto) {
		return 'rules.' + set + (proto ? '.' + proto : '');
	},

	formatRuleDescription(s, proto) {
		let descr = (s.length >= 1) ? (
			s.replace(/^c\.?(.*)/, '$1 CIDR').replace(/^i\.?(.*)/, '$1 IP')
			.replace(/^d\.?(.*)/, '$1 dnsmasq').replace(/^onion\.?(.*)/, '$1 onion')
			.replace(/^bi/, 'bypass IP').replace(/^bd/, 'bypass dnsmasq')
		) : '';
		return (proto) ? `${descr} (${proto.toUpperCase()})` : descr;
	},

	load() {
		return fs.exec_direct(tools.execPath, [ 'html-info' ], 'json').catch(e => {
			ui.addNotification(null, E('p', _('Unable to execute or read contents')
				+ ': %s [ %s ]'.format(e.message, tools.execPath)
			));
		})
	},

	render(data) {
		if(!data) {
			return;
		};

		try {
			data = JSON.parse(data);
		} catch(e) {};

		let initialNftData = (data && data.status === 'enabled') ? this.formatNftJson(data) : {};
		this.lastLayoutSignature = this.makeLayoutSignature(data, initialNftData);
		let statsContentWrapper = E('div', { 'id': 'statsContentWrapper' },
			this.buildContentSections(data)
		);

		poll.add(L.bind(this.pollInfo, this), this.pollInterval);

		return E([
			E('h2', { 'class': 'fade-in' },
				_('Ruantiblock') + ' - ' + _('Statistics')
			),
			E('div', { 'class': 'cbi-section-descr fade-in' }),
			statsContentWrapper,
		]);
	},

	handleSave     : null,
	handleSaveApply: null,
	handleReset    : null,
});
