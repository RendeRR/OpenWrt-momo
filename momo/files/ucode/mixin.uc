#!/usr/bin/ucode

'use strict';

import { cursor } from 'uci';
import { uci_bool, uci_int, uci_array, merge, trim_all, load_profile, save_profile } from '/etc/momo/ucode/include.uc';

const uci = cursor();

const config = {};

config['log'] = {};
config['log']['disabled'] = uci_bool(uci.get('momo', 'mixin', 'log_disabled'));
config['log']['level'] = uci.get('momo', 'mixin', 'log_level');
config['log']['timestamp'] = uci_bool(uci.get('momo', 'mixin', 'log_timestamp'));
config['log']['output'] = uci.get('momo', 'mixin', 'log_output');

config['dns'] = {};
config['dns']['strategy'] = uci.get('momo', 'mixin', 'dns_strategy');
config['dns']['disable_cache'] = uci_bool(uci.get('momo', 'mixin', 'dns_disable_cache'));
config['dns']['disable_expire'] = uci_bool(uci.get('momo', 'mixin', 'dns_disable_expire'));
config['dns']['independent_cache'] = uci_bool(uci.get('momo', 'mixin', 'dns_independent_cache'));
config['dns']['cache_capacity'] = uci_int(uci.get('momo', 'mixin', 'dns_cache_capacity'));
config['dns']['reverse_mapping'] = uci_bool(uci.get('momo', 'mixin', 'dns_reverse_mapping'));

config['ntp'] = {};
config['ntp']['enabled'] = uci_bool(uci.get('momo', 'mixin', 'ntp_enabled'));
config['ntp']['server'] = uci.get('momo', 'mixin', 'ntp_server');
config['ntp']['server_port'] = uci_int(uci.get('momo', 'mixin', 'ntp_server_port'));
config['ntp']['interval'] = uci.get('momo', 'mixin', 'ntp_interval');

config['experimental'] = {};

config['experimental']['cache_file'] = {};
config['experimental']['cache_file']['enabled'] = uci_bool(uci.get('momo', 'mixin', 'cache_enabled'));
config['experimental']['cache_file']['path'] = uci.get('momo', 'mixin', 'cache_path');
config['experimental']['cache_file']['store_fakeip'] = uci_bool(uci.get('momo', 'mixin', 'cache_store_fakeip'));
config['experimental']['cache_file']['store_rdrc'] = uci_bool(uci.get('momo', 'mixin', 'cache_store_rdrc'));

config['experimental']['clash_api'] = {};
config['experimental']['clash_api']['external_ui'] = uci.get('momo', 'mixin', 'external_control_ui_path');
config['experimental']['clash_api']['external_ui_download_url'] = uci.get('momo', 'mixin', 'external_control_ui_download_url');
config['experimental']['clash_api']['external_controller'] = uci.get('momo', 'mixin', 'external_control_api_listen');
config['experimental']['clash_api']['secret'] = uci.get('momo', 'mixin', 'external_control_api_secret');

let api_listen_str = uci.get('momo', 'mixin', 'singbox_api_listen') ?? '';
let api_listen = '';
let api_listen_port = 0;
if (api_listen_str) {
    let colon_idx = rindex(api_listen_str, ':');
    if (colon_idx != -1) {
        api_listen = substr(api_listen_str, 0, colon_idx);
        api_listen_port = +substr(api_listen_str, colon_idx + 1);
    }
}

config['services'] = [];

const profile = load_profile();

if (api_listen && api_listen_port) {
    let secret = uci.get('momo', 'mixin', 'singbox_api_secret');
    let dash_path = uci.get('momo', 'mixin', 'singbox_api_ui_path');
    let dash_url = uci.get('momo', 'mixin', 'singbox_api_ui_download_url');
    let tls_enabled = uci_bool(uci.get('momo', 'mixin', 'singbox_api_tls_enabled'));
    let tls_cert = uci.get('momo', 'mixin', 'singbox_api_tls_cert_path');
    let tls_key = uci.get('momo', 'mixin', 'singbox_api_tls_key_path');

    let found = false;

    if (type(profile['services']) == 'array') {
        for (let i = 0; i < length(profile['services']); i++) {
            if (profile['services'][i]['type'] == 'api') {
                found = true;
                profile['services'][i]['listen'] = api_listen;
                profile['services'][i]['listen_port'] = api_listen_port;

                if (secret) profile['services'][i]['secret'] = secret;
                else delete profile['services'][i]['secret'];

                if (type(profile['services'][i]['dashboard']) != 'object') profile['services'][i]['dashboard'] = {};
                profile['services'][i]['dashboard']['enabled'] = true;

                if (dash_path) profile['services'][i]['dashboard']['path'] = dash_path;
                else delete profile['services'][i]['dashboard']['path'];

                if (dash_url) profile['services'][i]['dashboard']['download_url'] = dash_url;
                else delete profile['services'][i]['dashboard']['download_url'];

                if (tls_enabled) {
                    if (type(profile['services'][i]['tls']) != 'object') profile['services'][i]['tls'] = {};
                    profile['services'][i]['tls']['enabled'] = true;
                    if (tls_cert) profile['services'][i]['tls']['certificate_path'] = tls_cert;
                    if (tls_key) profile['services'][i]['tls']['key_path'] = tls_key;
                } else {
                    delete profile['services'][i]['tls'];
                }
                break;
            }
        }
    }

    if (!found) {
        let api_service = {
            "type": "api",
            "listen": api_listen,
            "listen_port": api_listen_port
        };

        if (secret) api_service["secret"] = secret;

        api_service["dashboard"] = { "enabled": true };
        if (dash_path) api_service["dashboard"]["path"] = dash_path;
        if (dash_url) api_service["dashboard"]["download_url"] = dash_url;

        if (tls_enabled) {
            api_service["tls"] = { "enabled": true };
            if (tls_cert) api_service["tls"]["certificate_path"] = tls_cert;
            if (tls_key) api_service["tls"]["key_path"] = tls_key;
        }

        push(config['services'], api_service);
    }
}

save_profile(merge(profile, trim_all(config)));