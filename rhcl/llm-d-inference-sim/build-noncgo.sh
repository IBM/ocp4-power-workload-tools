mkdir -p tmp/
cd tmp/

curl -O -L https://github.com/llm-d/llm-d-inference-sim/archive/refs/tags/v0.8.2.zip && \
    dnf install unzip -y && \
    unzip v0.8.2.zip

cd llm-d-inference-sim-0.8.2
cp cmd/llm-d-inference-sim/main.go cmd/cmd.go

CGO_ENABLED=0 GOOS=linux GOARCH=ppc64le go build -o bin/llm-d-inference-sim ./cmd/cmd.go
CGO_ENABLED=0 GOOS=linux GOARCH=s390x go build -o bin/llm-d-inference-sim ./cmd/cmd.go