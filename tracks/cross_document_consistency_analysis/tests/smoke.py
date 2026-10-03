"""Contract smoke; no semantic classifier. --cases supplies agent evaluation inputs."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import yaml

TRACK = "cross_document_consistency_analysis"
PHASES = "ingest intake source_inventory document_model consistency_analysis conflict_analysis impact_analysis disposition_analysis critical_review analysis_package".split()
CASES = {
 "A": {"sources": [{"id":"s-a","repository":"repo-a","path":"docs/policy.md","text":"Every submitted item requires review before publication."},{"id":"s-b","repository":"repo-b","path":"docs/process.md","text":"Publication occurs only after review of the submitted item."}],"assessment":"Agreement with source locators; no artificial conflict."},
 "B": {"sources": [{"id":"s-a","repository":"repo-a","path":"docs/policy.md","text":"Every submitted item requires review before publication."},{"id":"s-b","repository":"repo-b","path":"docs/process.md","text":"For the same item class, publication always occurs before review."}],"assessment":"Material contradiction linked to both claims and locators; no unsupported resolution."},
 "C": {"sources": [{"id":"s-a","repository":"repo-a","path":"docs/glossary.md","text":"A submission is the same entity called a request in the process document."},{"id":"s-b","repository":"repo-b","path":"docs/process.md","text":"Each request requires review before publication."},{"id":"s-c","repository":"repo-a","path":"docs/policy.md","text":"Each submission requires review before publication."}],"assessment":"Terminology drift or evidenced alias; no false material contradiction."},
 "D": {"sources": [{"id":"s-a","repository":"repo-a","path":"docs/old-decision.md","text":"Decision dec-old requires a manual review."},{"id":"s-b","repository":"repo-b","path":"docs/current-decision.md","text":"Approved decision dec-current explicitly supersedes dec-old for the same scope, replacing manual review with automated checks."}],"assessment":"Explicit supersession with provenance; stale old claim distinguished from current authority, never newest-file rule."},
 "E": {"sources": [{"id":"s-a","repository":"repo-a","path":"docs/decision-a.md","text":"Review must be manual. Scope: all submissions. Authority owner unspecified."},{"id":"s-b","repository":"repo-b","path":"docs/decision-b.md","text":"Review must be automated. Scope: all submissions. Authority owner unspecified."}],"assessment":"Conflict and authority uncertainty remain OPEN/TBD; identify evidence needed rather than invent priority."},
 "F": {"sources": [{"id":"s-a","repository":"repo-a","path":"docs/prior-findings.yaml","text":"id: issue-017\nstatus: OPEN\nhistory: [{date: 2025-01-01, origin: docs/prior-review.md}]\nmeaning: review order is contradictory"},{"id":"s-b","repository":"repo-b","path":"docs/current-policy.md","text":"Review order for all submissions remains undocumented."}],"assessment":"Preserve issue-017 identity, meaning, history and provenance; supported disposition with explicit current uncertainty."}
}

def load(path):
 return yaml.safe_load(path.read_text(encoding="utf-8"))

def main():
 parser=argparse.ArgumentParser();parser.add_argument("--cases",action="store_true");parser.add_argument("--runtime-contracts",action="store_true");args=parser.parse_args()
 if args.cases:
  print(json.dumps(CASES,indent=2));return
 repo=Path(__file__).resolve().parents[3];tree=repo/"tracks"/TRACK
 production=[p for folder in (tree,repo/"templates/prompts"/TRACK) for p in folder.rglob("*") if p.is_file()]
 assert len(production)==43 and all(b"\r" not in p.read_bytes() for p in production)
 track=load(tree/"track.yaml")["track"]
 assert track["id"]==TRACK and track["phases"]==PHASES
 assert track["initial_phase"]==PHASES[0] and track["final_phase"]==PHASES[-1]
 assert set(track["transitions"])==set(PHASES[:-1])
 produced=set();all_prompts=[]
 for i,p in enumerate(PHASES):
  if i<9:
   edge=track["transitions"][p];assert edge["next"]==PHASES[i+1] and edge["contract"]=={"emit_handoff":True,"consume_previous":True} and "skip_when" not in edge
  phase=load(tree/"phases"/(p+".yaml"))["phase"]
  assert phase["id"]==p and phase["skills"]==[]
  out=phase["outputs"]["create_artifacts"]
  assert phase["completion"]["strategy"]=="required_artifacts_exist"
  assert [x["path"] for x in phase["completion"]["required_artifacts"]]==out
  assert ("investigations/20_handoff.json" in out)==(i<9)
  for r in phase["read_sources"]:
   if r.startswith("{{CARD_DIR}}/") and r not in ("{{CARD_DIR}}/ingest","{{CARD_DIR}}/implementation"):
    assert r.removeprefix("{{CARD_DIR}}/") in produced,(p,r)
  if i>=3:
   assert phase["read_sources_from"]=="required_inventory_sources" and phase["evidence_manifest"]=="analysis/10_source_manifest.yaml"
  assert all("TARGET_REPOS" not in r for r in phase["read_sources"])
  family=repo/"templates/prompts"/TRACK/p;prompt=(family/"prompt_v1.md").read_text(encoding="utf-8");all_prompts.append(prompt)
  assert prompt.startswith("{{RUNTIME_ENVIRONMENT}}\n") and phase["prompt"]["path"]==f"templates/prompts/{TRACK}/{p}/prompt_v1.md"
  assert (family/"ACTIVE").read_text().strip()=="1"
  meta=dict(line.split("=",1) for line in (family/"prompt_v1.meta").read_text().splitlines() if "=" in line)
  assert meta["version"]=="v1"
  for s in meta["required_substrings"].split("|"):assert s in prompt,(p,s)
  for o in out:assert "{{CARD_DIR}}/"+o in prompt.split("WRITE_SCOPE\n",1)[1].split("\n\nRULES",1)[0]
  assert not re.search(r"\$\{(?:CARD|CARD_DIR|RUNTIME_ROOT|CONFIG_SOURCE|EAW_WORKDIR)\}",prompt)
  if i<9:
   expected=json.dumps({"from_phase":p,"status":"completed","messages":[],"codes":[]},separators=(",",":"))
   assert any("printf" in line and expected in line and '> "{{CARD_DIR}}/investigations/20_handoff.json"' in line for line in prompt.splitlines())
  produced.update(out)
 package=load(tree/"phases/analysis_package.yaml")["phase"]
 assert package["delivery_contract"]=="required" and package["package_artifact"]=="analysis/70_package_handoff.md"
 assert package["target_delivery_paths"]==["docs/cross-document-consistency-"+n for n in ("analysis.md","findings.yaml","decisions.yaml")]
 text="\n".join(all_prompts)
 for prohibited in ("SecOpinion","Health","medicine","OpenAI","LLM","BR-051","CR-01","CR-02"):assert prohibited.lower() not in text.lower()
 assert len(list(tree.glob("phases/*.yaml")))==10
 assert len(list((repo/"templates/prompts"/TRACK).glob("*/*")))==30
 for case in CASES.values():
  assert len(case["sources"])>=2 and len({s["id"] for s in case["sources"]})==len(case["sources"])
  assert {s["repository"] for s in case["sources"]}=={"repo-a","repo-b"}
  assert all(s["path"].startswith("docs/") for s in case["sources"])
 print("PASS structural: 10 phases, 9 edges, producer/consumer wiring, own completion, 30 prompt-family files, propagation/delivery bindings, genericity and boundaries")
 print("A-F cognitive: NOT_RUN; --cases emits neutral inputs for governed agent execution. Structural PASS is not semantic evidence.")
 print("I/J structural: PASS; final product/diff validation remains required.")
 if args.runtime_contracts:runtime_contracts(repo)
 else:print("G/H runtime helper checks: NOT_RUN (use --runtime-contracts as orchestrator)")

def bash_path(path):
 s=Path(path).resolve().as_posix();return "/"+s[0].lower()+s[2:] if re.match(r"^[A-Za-z]:",s) else s

def runtime_contracts(repo):
 bash=r"C:\Program Files\Git\bin\bash.exe" if os.name=="nt" else "bash"
 with tempfile.TemporaryDirectory(prefix="document-consistency-contract-") as temp:
  d=Path(temp)
  for key in ("repo-a","repo-b"):
   (d/key/"docs").mkdir(parents=True);(d/key/"docs/source.md").write_text("Neutral source\n",newline="\n")
  conf=d/"repos.conf";conf.write_text("\n".join(k+"|"+bash_path(d/k)+"|target" for k in ("repo-a","repo-b"))+"\n",newline="\n")
  manifest=d/"manifest.yaml";manifest.write_text("sources:\n"+"".join("  - id: source-"+str(i)+"\n    repository: "+key+"\n    path: docs/source.md\n    required: true\n    availability: available\n" for i,key in enumerate(("repo-a","repo-b"))),newline="\n")
  phase=d/"phase.yaml";phase.write_text("phase:\n  target_delivery_paths:\n    - docs/report.md\n",newline="\n")
  selection=d/"selection.md";selection.write_text("DELIVERY_TARGETS:\n- repo-b\nANALYSIS_STATUS: INCOMPLETE\nPERSISTENCE_STATUS: NOT_PERSISTED\n",newline="\n")
  source=d/"report.md";source.write_text("Document consistency report\nEvidence from two repositories.\n",newline="\n")
  canonical_result=subprocess.run([bash,"-s"],input="export PATH=/usr/bin:/bin\nrealpath -e -- '"+bash_path(d).replace("'","'\\''")+"'\n",text=True,capture_output=True)
  assert canonical_result.returncode==0,canonical_result.stderr
  canonical_temp=canonical_result.stdout.strip()
  def q(p):
   resolved=Path(p).resolve()
   try:value=canonical_temp+"/"+resolved.relative_to(d.resolve()).as_posix()
   except ValueError:value=bash_path(p)
   return "'"+value.replace("'","'\\''")+"'"
  shell="export PATH=/usr/bin:/bin:/mingw64/bin:/cmd\nsource "+q(repo/"scripts/lib/analysis_delivery_contract.sh")+"\n"
  shell+="eaw_delivery_resolve_inventory_sources "+q(manifest)+" "+q(conf)+"\n"
  shell+="printf 'DIAGNOSTIC selection\\n' >&2\n"
  shell+="eaw_delivery_selection_targets "+q(selection)+" | cat -A >&2\n"
  shell+="printf 'DIAGNOSTIC phase\\n' >&2\ncat -A "+q(phase)+" >&2\n"
  shell+="printf 'DIAGNOSTIC derived allowlist\\n' >&2\n"
  shell+="eaw_delivery_derive_write_allowlist "+" ".join(q(p) for p in (conf,phase,d/"absent.lock",d/"case"))+" '' "+q(selection)+" true | cat -A >&2\n"
  shell+="eaw_delivery_persist_selected_file "+" ".join(q(p) for p in (source,d/"repo-b/docs/report.md",conf,phase,d/"absent.lock",d/"case",selection))+" || exit $?\n"
  result=subprocess.run([bash,"-s"],input=shell,text=True,capture_output=True)
  assert result.returncode==0,(result.stdout,result.stderr)
  lines=result.stdout.splitlines();assert len(lines)==2 and {line.split("\t")[0] for line in lines}=={"repo-a","repo-b"}
  assert (d/"repo-b/docs/report.md").read_bytes()==source.read_bytes() and not (d/"repo-a/docs/report.md").exists()
  assert "CARD_ID" not in source.read_text() and "EAW" not in source.read_text()
  print("PASS G/H: real helper propagates two repository keys; persists byte-identical source only to independently selected repo-b. Temporary fixtures removed on exit.")

if __name__=="__main__":main()
