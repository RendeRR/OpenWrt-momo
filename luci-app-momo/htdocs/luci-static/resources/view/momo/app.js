'use strict';
'require form';
'require view';
'require uci';
'require poll';
'require ui';
'require tools.momo as momo';

function renderStatus(running) {
    return updateStatus(E('input', { id: 'core_status', style: 'border: unset; font-style: italic; font-weight: bold;', readonly: '' }), running);
}

function updateStatus(element, running) {
    if (element) {
        element.style.color = running ? 'green' : 'red';
        element.value = running ? _('Running') : _('Not Running');
    }
    return element;
}

return view.extend({
    load: function () {
        return Promise.all([
            uci.load('momo'),
            momo.version(),
            momo.status(),
            momo.listProfiles()
        ]);
    },
    render: function (data) {
        const subscriptions = uci.sections('momo', 'subscription');
        const appVersion = data[1].app ?? '';
        const coreVersion = data[1].core ?? '';
        const running = data[2];
        const profiles = data[3];

        let m, s, o;

        m = new form.Map('momo', _('Momo'), `${_('Transparent Proxy with sing-box on OpenWrt.')} <a href="https://github.com/nikkinikki-org/OpenWrt-momo/wiki" target="_blank">${_('How To Use')}</a>`);

        s = m.section(form.TableSection, 'placeholder', _('Status'));
        s.anonymous = true;

        o = s.option(form.DummyValue, '_app_version', _('App Version'));
        o.width = '120px';
        o.cfgvalue = function () {
            return E('span', { style: 'white-space: nowrap;' }, appVersion);
        };

        o = s.option(form.DummyValue, '_core_version', _('Core Version'));
        o.width = '150px';
        o.cfgvalue = function () {
            return E('span', { style: 'white-space: nowrap;' }, coreVersion);
        };

        o = s.option(form.DummyValue, '_core_status', _('Core Status'));
        o.cfgvalue = function () {
            return renderStatus(running);
        };
        poll.add(function () {
            return L.resolveDefault(momo.status()).then(function (running) {
                updateStatus(document.getElementById('core_status'), running);
            });
        });

        o = s.option(form.Button, 'reload');
        o.inputstyle = 'action';
        o.inputtitle = _('Reload Service');
        o.onclick = function () {
            return momo.reload();
        };

        o = s.option(form.Button, 'restart');
        o.inputstyle = 'negative';
        o.inputtitle = _('Restart Service');
        o.onclick = function () {
            return momo.restart();
        };

        o = s.option(form.Button, 'update_dashboard');
        o.inputstyle = 'positive';
        o.inputtitle = _('Update Dashboard');
        o.onclick = function () {
            return momo.updateDashboard();
        };

        o = s.option(form.Button, 'open_dashboard');
        o.inputtitle = _('Open Dashboard');
        o.onclick = function () {
            return momo.openDashboard();
        };

        o = s.option(form.Button, 'open_singbox_dashboard');
        o.inputtitle = _('Open Sing-box Dashboard');
        o.onclick = function () {
            return momo.openSingboxDashboard();
        };

        s = m.section(form.NamedSection, 'placeholder', 'placeholder', _('Sing-Box Update'), _('The command <code>curl -fsSL https://sing-box.app/install.sh | sh -s -- --version &lt;version&gt;</code> will be executed.'));

        o = s.option(form.DummyValue, '_update_widget', '');
        o.renderWidget = function(section_id) {
            let select = E('select', { id: 'singbox_version_select', style: 'width: 260px; margin-right: 8px;', class: 'cbi-input-select' }, [
                E('option', { value: '' }, _('Loading versions...'))
            ]);

            let mirrorSelect = E('select', { id: 'singbox_mirror_select', style: 'width: 220px; margin-right: 8px;', class: 'cbi-input-select' }, [
                E('option', { value: 'auto' }, _('Auto (GitHub + Mirror Fallback)')),
                E('option', { value: 'ghfast' }, _('Mirror (ghfast.top)')),
                E('option', { value: 'ghproxy' }, _('Mirror (gh-proxy.com)')),
                E('option', { value: 'direct' }, _('GitHub Direct'))
            ]);

            const populateReleases = function(releases) {
                select.innerHTML = '';
                if (!Array.isArray(releases) || releases.length === 0) {
                    select.appendChild(E('option', { value: '' }, _('No versions found')));
                    return;
                }

                const stableGroup = E('optgroup', { label: _('Stable Releases') });
                const prereleaseGroup = E('optgroup', { label: _('Pre-releases (Beta / Alpha)') });
                let stableCount = 0;
                let prereleaseCount = 0;
                let defaultSelectedValue = '';

                releases.forEach(function(r) {
                    if (!r || !r.tag_name) return;
                    const tag = r.tag_name;
                    const cleanVer = tag.replace(/^v/, '');
                    const isPre = Boolean(r.prerelease || tag.indexOf('-') !== -1);
                    const isInstalled = Boolean(coreVersion && cleanVer === coreVersion.trim());

                    let label = tag;
                    if (!isPre && stableCount === 0) {
                        label += ' (' + _('Latest') + ')';
                        defaultSelectedValue = tag;
                    }
                    if (isInstalled) {
                        label += ' ✓ [' + _('Installed') + ']';
                    }

                    const opt = E('option', { value: tag }, label);
                    if (isPre) {
                        prereleaseGroup.appendChild(opt);
                        prereleaseCount++;
                    } else {
                        stableGroup.appendChild(opt);
                        stableCount++;
                    }
                });

                if (stableCount > 0) select.appendChild(stableGroup);
                if (prereleaseCount > 0) select.appendChild(prereleaseGroup);

                if (defaultSelectedValue) {
                    select.value = defaultSelectedValue;
                }
            };

            const apiUrl = 'https://api.github.com/repos/SagerNet/sing-box/releases?per_page=40';
            fetch(apiUrl)
                .then(function(res) {
                    if (!res.ok) throw new Error('GitHub API error');
                    return res.json();
                })
                .then(populateReleases)
                .catch(function() {
                    fetch('https://ghfast.top/' + apiUrl)
                        .then(function(res) { return res.json(); })
                        .then(populateReleases)
                        .catch(function() {
                            select.innerHTML = '';
                            select.appendChild(E('option', { value: '' }, _('Failed to load versions')));
                        });
                });

            let btn = E('button', {
                class: 'cbi-button cbi-button-action',
                click: function(ev) {
                    const rawVersion = document.getElementById('singbox_version_select').value;
                    const mirror = document.getElementById('singbox_mirror_select').value || 'auto';
                    const version = rawVersion.replace(/^v/, '');
                    if (!version) return;

                    ui.showModal(_('Updating Sing-Box'), [
                        E('p', { class: 'spinning' }, _('Downloading and installing, please wait...'))
                    ]);

                    return momo.updateSingbox(version, mirror).then((res) => {
                        ui.showModal(_('Updating Sing-Box'), [
                            E('pre', { style: 'white-space: pre-wrap' }, res.result || res),
                            E('div', { class: 'right' }, [
                                E('button', { class: 'btn', click: function() { ui.hideModal(); location.reload(); } }, _('Close'))
                            ])
                        ]);
                    }).catch((err) => {
                        ui.showModal(_('Updating Sing-Box'), [
                            E('pre', { style: 'white-space: pre-wrap; color: red;' }, String(err)),
                            E('div', { class: 'right' }, [
                                E('button', { class: 'btn', click: function() { ui.hideModal(); location.reload(); } }, _('Close'))
                            ])
                        ]);
                    });
                }
            }, _('Install'));

            return E('div', { style: 'display: flex; align-items: center; flex-wrap: wrap; gap: 6px;' }, [ select, mirrorSelect, btn ]);
        };

        s = m.section(form.NamedSection, 'config', 'config', _('App Config'));

        o = s.option(form.Flag, 'enabled', _('Enable'));
        o.rmempty = false;

        o = s.option(form.ListValue, 'profile', _('Choose Profile'));
        o.optional = true;

        for (const profile of profiles) {
            o.value('file:' + profile.name, _('File:') + profile.name);
        };

        for (const subscription of subscriptions) {
            o.value('subscription:' + subscription['.name'], _('Subscription:') + subscription.name);
        };

        o = s.option(form.Value, 'start_delay', _('Start Delay'));
        o.datatype = 'uinteger';
        o.placeholder = _('Start Immidiately');

        o = s.option(form.Flag, 'scheduled_restart', _('Scheduled Restart'));
        o.rmempty = false;

        o = s.option(form.Value, 'scheduled_restart_cron', _('Scheduled Restart Cron'));
        o.retain = true;
        o.rmempty = false;
        o.depends('scheduled_restart', '1');

        o = s.option(form.Flag, 'test_profile', _('Test Profile'));
        o.rmempty = false;

        o = s.option(form.Flag, 'format_profile', _('Format Profile'));
        o.rmempty = false;

        o = s.option(form.Flag, 'core_only', _('Core Only'));
        o.rmempty = false;

        s = m.section(form.NamedSection, 'procd', 'procd', _('procd Config'));

        s.tab('general', _('General Config'));

        o = s.taboption('general', form.Flag, 'fast_reload', _('Fast Reload'));
        o.rmempty = false;

        s.tab('rlimit', _('RLIMIT Config'));

        o = s.taboption('rlimit', form.Value, 'rlimit_nproc_soft', _('Number of Processes Soft Limit'));
        o.datatype = 'uinteger';

        o = s.taboption('rlimit', form.Value, 'rlimit_nproc_hard', _('Number of Processes Hard Limit'));
        o.datatype = 'uinteger';

        o = s.taboption('rlimit', form.Value, 'rlimit_address_space_soft', _('Address Space Size Soft Limit'));
        o.datatype = 'uinteger';
        o.placeholder = _('Unlimited');

        o = s.taboption('rlimit', form.Value, 'rlimit_address_space_hard', _('Address Space Size Hard Limit'));
        o.datatype = 'uinteger';
        o.placeholder = _('Unlimited');

        o = s.taboption('rlimit', form.Value, 'rlimit_data_soft', _('Heap Size Soft Limit'));
        o.datatype = 'uinteger';
        o.placeholder = _('Unlimited');

        o = s.taboption('rlimit', form.Value, 'rlimit_data_hard', _('Heap Size Hard Limit'));
        o.datatype = 'uinteger';
        o.placeholder = _('Unlimited');

        o = s.taboption('rlimit', form.Value, 'rlimit_stack_soft', _('Stack Size Soft Limit'));
        o.datatype = 'uinteger';
        o.placeholder = _('Unlimited');

        o = s.taboption('rlimit', form.Value, 'rlimit_stack_hard', _('Stack Size Hard Limit'));
        o.datatype = 'uinteger';
        o.placeholder = _('Unlimited');

        o = s.taboption('rlimit', form.Value, 'rlimit_nofile_soft', _('Number of Open Files Soft Limit'));
        o.datatype = 'uinteger';

        o = s.taboption('rlimit', form.Value, 'rlimit_nofile_hard', _('Number of Open Files Hard Limit'));
        o.datatype = 'uinteger';

        s.tab('environment_variable', _('Environment Variable Config'));

        o = s.taboption('environment_variable', form.Value, 'env_go_max_procs', 'GOMAXPROCS');
        o.datatype = 'uinteger';
        o.placeholder = _('Unlimited');

        o = s.taboption('environment_variable', form.Value, 'env_go_mem_limit', 'GOMEMLIMIT');
        o.datatype = 'uinteger';
        o.placeholder = _('Unlimited');

        return m.render();
    }
});
