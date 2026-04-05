include traceforge.__init__;
include traceforge.schema;
include traceforge.ingest;
include traceforge.parser;
include traceforge.features;
include traceforge.clustering;
include traceforge.critical;
include traceforge.graph_build;
include traceforge.analysis;
include traceforge.llm_ops;
include traceforge.eval;
include traceforge.reporting;
include traceforge.provider_config;
include traceforge.api;
include traceforge.ui;

cl import from traceforge.ui { app as TraceForgeApp }

cl {
    def:pub app() -> JsxElement {
        return <TraceForgeApp />;
    }
}

with entry {}
