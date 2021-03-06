alias vim="nvim"
alias fw="fly -t wings"
alias fwl="fw login -n system-team-pcf-bosh-pcf-bosh-1-2688"

function sp(){
  pushd "$HOME/workspace/ci" > /dev/null
    lpass sync

    fly -t wings sp -p pcf-bosh -c pipelines/pcf-bosh.yml -l <(lpass show --notes 5986431050471091932) \
        --var env_name=ol-smokey \
        --var set_to_tag_filter_to_lock_cf_deployment=tag_filter \
        --var p-ert-branch=1.9

    fly -t wings sp -p pcf-bosh-floating -c pipelines/pcf-bosh.yml -l <(lpass show --notes 5986431050471091932) \
        --var env_name=monte-nuovo \
        --var set_to_tag_filter_to_lock_cf_deployment=ignoreme \
        --var p-ert-branch=master

    fly -t wings sp -p upgrade -c pipelines/upgrade-ert.yml -l <(lpass show --notes 5986431050471091932) \
        --var env_name=nanga-parbat

    fly -t wings sp -p pcf-bosh-aws -c pipelines/pcf-bosh-aws.yml -l <(lpass show --notes 5986431050471091932) \
        --var env_name=mt-rogers

  popd > /dev/null
}

function bosh_with_env() {
    env_name="$1"
    shift

    iaas="$1"
    shift

    yaml="$(gsutil cat gs://pcf-bosh-ci/\"$env_name\"-bosh-vars-store.yml)"
    uaa_client_secret="$(bosh int <(echo "$yaml") --path /ci_secret)"

    ca_cert="$(bosh int <(echo "$yaml") --path /director_ssl/ca)"

    bosh -e director.$env_name.$iaas.pcf-bosh.cf-app.com --client=ci --client-secret=$uaa_client_secret --ca-cert="$ca_cert" $*
}

function bsmokey() {
    bosh_with_env ol-smokey gcp $*
}

function bmonte() {
    bosh_with_env monte-nuovo gcp $*
}

function bnanga() {
    bosh_with_env nanga-parbat gcp $*
}

function brogers() {
    bosh_with_env mt-rogers aws $*
}

function env_cf_password() {
    local environment_name=$1

    gsutil cat gs://pcf-bosh-ci/\"$environment_name\"-cf-vars-store.yml | \
    grep uaa_scim_users_admin_password | \
    awk '{print $2}'
}

function smokeypass() {
    env_cf_password ol-smokey
}

function montepass() {
    env_cf_password monte-nuovo
}

function nangapass() {
    env_cf_password nanga-parbat
}

function rogerspass() {
    env_cf_password mt-rogers
}
