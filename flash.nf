#!/usr/bin/env nextflow

import Helper
import CollectInitialMetadata

// Pipeline version
if (workflow.commitId){
    version = "0.1 $workflow.revision"
} else {
    version = "0.1 (local version)"
}

params.help = false
if (params.help){
    Help.print_help(params)
    exit 0
}

def infoMap = [:]
if (params.containsKey("fastq")){
    infoMap.put("fastq", file(params.fastq).size())
}
if (params.containsKey("fasta")){
    if (file(params.fasta) instanceof LinkedList){
        infoMap.put("fasta", file(params.fasta).size())
    } else {
        infoMap.put("fasta", 1) 
    }
}
if (params.containsKey("accessions")){
    // checks if params.accessions is different from null
    if (params.accessions) {
        BufferedReader reader = new BufferedReader(new FileReader(params.accessions));
        int lines = 0;
        while (reader.readLine() != null) lines++;
        reader.close();
        infoMap.put("accessions", lines)
    }
}

Help.start_info(infoMap, "$workflow.start", "$workflow.profile")
CollectInitialMetadata.print_metadata(workflow)
    

// Placeholder for main input channels
if (params.fastq instanceof Boolean){exit 1, "'fastq' must be a path pattern. Provide value:'$params.fastq'"}
if (!params.fastq){ exit 1, "'fastq' parameter missing"}
IN_fastq_raw = Channel.fromFilePairs(params.fastq).ifEmpty { exit 1, "No fastq files provided with pattern:'${params.fastq}'" }

// Placeholder for secondary input channels


// Placeholder for extra input channels


// Placeholder to fork the raw input channel

IN_fastq_raw.set{ flash_in_1_0 }


// Check parameters are numbers
def numb = 'parameter must be a number. Provided value:'
if ( !params.flashMinOverlap_1_1.toString().isNumber() ){
    exit 1, "'flashMinOverlap_1_1' ${numb} '${params.flashMinOverlap_1_1}'"
}
if ( !params.flashMaxOverlap_1_1.toString().isNumber() ){
    exit 1, "'flashMaxOverlap_1_1' ${numb} '${params.flashMaxOverlap_1_1}'"
}
if ( !params.flashMaxMismatch_1_1.toString().isNumber() ){
    exit 1, "'flashMaxMismatch_1_1' ${numb} '${params.flashMaxMismatch_1_1}'"
}
if ( !params.flashNumThreads_1_1.toString().isNumber() ){
    exit 1, "'flashNumThreads_1_1' ${numb} '${params.flashNumThreads_1_1}'"
}
min_overlap  = Channel.value(params.flashMinOverlap_1_1)
max_overlap  = Channel.value(params.flashMaxOverlap_1_1)
max_mismatch = Channel.value(params.flashMaxMismatch_1_1)
num_threads  = Channel.value(params.flashNumThreads_1_1)

// Param to compress output files with gzip
compress = params.flashCompress_1_1 ? "--compress" : ""
// Params for "extra" files
keepHist    = params.keepHists_1_1 ? true : ''
keepNotComb = params.keepNotCombined_1_1 ? true : ''

process flash_1_1 {
        if ( params.platformHTTP != null ) {
        beforeScript "PATH=${workflow.projectDir}/bin:\$PATH; export PATH; set_dotfiles.sh; startup_POST.sh $params.projectId $params.pipelineId 1_1 $params.platformHTTP"
        afterScript "final_POST.sh $params.projectId $params.pipelineId 1_1 $params.platformHTTP; report_POST.sh $params.projectId $params.pipelineId 1_1 $params.sampleName $params.reportHTTP $params.currentUserName $params.currentUserId flash_1_1 \"$params.platformSpecies\" true"
    } else {
        beforeScript "PATH=${workflow.projectDir}/bin:\$PATH; set_dotfiles.sh"
        }

    tag { sample_id }
    publishDir "results/flash_1_1/", pattern: "*.extendedFrags.fastq"
    publishDir "results/flash_1_1/", pattern: "*.notCombined_*.fastq"
    publishDir "results/flash_1_1/", pattern: "*.hist*.fastq"

    input:
    set sample_id, file(fastq_pair) from flash_in_1_0

    val min_overlap  from min_overlap
    val max_overlap  from max_overlap
    val max_mismatch from max_mismatch
    val num_threads  from num_threads

    output:
    set sample_id, file("*.extendedFrags.fastq") into flash_output_1_1
    set sample_id, val("1_1_flash"), file(".status"), file(".warning"), file(".fail"), file(".command.log") into STATUS_flash_1_1
set sample_id, val("flash_1_1"), val("1_1"), file(".report.json"), file(".versions"), file(".command.trace") into REPORT_flash_1_1
file ".versions"

    script:
    """
    flash --min-overlap=${min_overlap} \
          --max-overlap=${max_overlap} \
          --max-mismatch-density=${max_mismatch} \
          --output-prefix=${sample_id} \
          --threads=${num_threads} \
          ${compress} \
          ${fastq_pair[0]} ${fastq_pair[1]} \
          > ${sample_id}.flash.log 2>&1

    #[ -z "${keepHist}" ] \
    #    && rm -f ${sample_id}.histogram* ${sample_id}.hist*
    #[ -z "${keepNotComb}" ] \
    #    && rm -f ${sample_id}.notCombined_[12].fastq*
    """
    //TODO: create "template flash.py" with other app options, OR implement all here with checks e.g. isNumber
    //TODO: record num reads after too finished

}



/** STATUS
Reports the status of a sample in any given process.
*/
process status {

    tag { sample_id }
    publishDir "pipeline_status/$task_name"

    input:
    set sample_id, task_name, status, warning, fail, file(log) from STATUS_flash_1_1

    output:
    file '*.status' into master_status
    file '*.warning' into master_warning
    file '*.fail' into master_fail
    file '*.log'

    """
    echo $sample_id, $task_name, \$(cat $status) > ${sample_id}_${task_name}.status
    echo $sample_id, $task_name, \$(cat $warning) > ${sample_id}_${task_name}.warning
    echo $sample_id, $task_name, \$(cat $fail) > ${sample_id}_${task_name}.fail
    echo "\$(cat .command.log)" > ${sample_id}_${task_name}.log
    """
}

process compile_status_buffer {

    input:
    file status from master_status.buffer( size: 5000, remainder: true)
    file warning from master_warning.buffer( size: 5000, remainder: true)
    file fail from master_fail.buffer( size: 5000, remainder: true)

    output:
    file 'master_status_*.csv' into compile_status_buffer
    file 'master_warning_*.csv' into compile_warning_buffer
    file 'master_fail_*.csv' into compile_fail_buffer

    """
    cat $status >> master_status_${task.index}.csv
    cat $warning >> master_warning_${task.index}.csv
    cat $fail >> master_fail_${task.index}.csv
    """
}

process compile_status {

    publishDir 'reports/status'

    input:
    file status from compile_status_buffer.collect()
    file warning from compile_warning_buffer.collect()
    file fail from compile_fail_buffer.collect()

    output:
    file "*.csv"

    """
    cat $status >> master_status.csv
    cat $warning >> master_warning.csv
    cat $fail >> master_fail.csv
    """

}


/** Reports
Compiles the reports from every process
*/
process report {

    tag { sample_id }

    input:
    set sample_id,
            task_name,
            pid,
            report_json,
            version_json,
            trace from REPORT_flash_1_1

    output:
    file "*" optional true into master_report

    """
    prepare_reports.py $report_json $version_json $trace $sample_id $task_name 1 $pid $workflow.scriptId $workflow.runName
    """

}

workflow.onComplete {
  // Display complete message
  log.info "Completed at: " + workflow.complete
  log.info "Duration    : " + workflow.duration
  log.info "Success     : " + workflow.success
  log.info "Exit status : " + workflow.exitStatus
}

workflow.onError {
  // Display error message
  log.info "Workflow execution stopped with the following message:"
  log.info "  " + workflow.errorMessage
}
