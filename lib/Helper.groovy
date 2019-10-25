class Help {

    static def start_info(Map info, String time, String profile) {

        println ""
        println "============================================================"
        println "                F L O W C R A F T"
        println "============================================================"
        println "Built using flowcraft v1.4.2"
        println ""
        if (info.containsKey("fastq")){
        int nsamples = info.fastq / 2
        println " Input FastQ                 : $info.fastq"
        println " Input samples               : $nsamples"
        }
        if (info.containsKey("fasta")){
        println " Input Fasta                 : $info.fasta"
        }
        if (info.containsKey("accessions")){
        println " Input accessions            : $info.accessions"
        }
        println " Reports are found in        : ./reports"
        println " Results are found in        : ./results"
        println " Profile                     : $profile"
        println ""
        println "Starting pipeline at $time"
        println ""

    }

    static void complete_info(nextflow.script.WorkflowMetadata wf) {

        println ""
        println "Pipeline execution summary"
        println "=========================="
        println "Completed at                 : $wf.complete"
        println "Duration                     : $wf.duration"
        println "Success                      : $wf.success"
        println "Work directory               : $wf.workDir"
        println "Exit status                  : $wf.exitStatus"
        println ""

    }

    static def print_help(Map params) {

        println ""
        println "============================================================"
        println "                F L O W C R A F T"
        println "============================================================"
        println "Built using flowcraft v1.4.2"
        println ""
        println ""
        println "Usage: "
        println "    nextflow run flash.nf"
        println ""
        println "       --fastq                     Path expression to paired-end fastq files. (default: $params.fastq) (default: 'fastq/*_{1,2}.*')"
        println "       "
        println "       Component 'FLASH_1_1'"
        println "       ---------------------"
        println "       --flashMinOverlap_1_1       minimum required overlap length between two reads to provide a confident overlap. (default: 30)"
        println "       --flashMaxOverlap_1_1       Maximum overlap length expected in approximately 90% of read pairs. (default: 150)"
        println "       --flashMaxMismatch_1_1      Maximum allowed ratio between the number of mismatched base pairs and the overlap length. (default: 0.1)"
        println "       --flashNumThreads_1_1       The number of worker threads to use. To match incoming read order, use '1'. (default: 1)"
        println "       --flashCompress_1_1         Write gzip compressed output files (default: false)"
        println "       --keepHist_1_1              Keeps .hist and .histogram files. (default: false)"
        println "       --keepNotCombined_1_1       Keeps unmerged _notCombined*.fastq files. (default: false)"
        
    }

}

class CollectInitialMetadata {

    public static void print_metadata(nextflow.script.WorkflowMetadata workflow){

        def treeDag = new File("${workflow.projectDir}/.treeDag.json").text
        def forkTree = new File("${workflow.projectDir}/.forkTree.json").text

        def metadataJson = "{'nfMetadata':{'scriptId':'${workflow.scriptId}',\
'scriptName':'${workflow.scriptName}',\
'profile':'${workflow.profile}',\
'container':'${workflow.container}',\
'containerEngine':'${workflow.containerEngine}',\
'commandLine':'${workflow.commandLine}',\
'runName':'${workflow.runName}',\
'sessionId':'${workflow.sessionId}',\
'projectDir':'${workflow.projectDir}',\
'launchDir':'${workflow.launchDir}',\
'startTime':'${workflow.start}',\
'dag':${treeDag},\
'forks':${forkTree}}}"

        def json = metadataJson.replaceAll("'", '"')

        def jsonFile = new File(".metadata.json")
        jsonFile.write json
    }
}