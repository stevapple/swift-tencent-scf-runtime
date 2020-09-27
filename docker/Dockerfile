ARG swift_version=5.2.5
FROM stevapple/swift-scf:$swift_version
# needed to do again after FROM due to docker limitation
ARG swift_version

# dependencies
RUN yum install -y wget perl-Digest-SHA lsof dnsutils netcat-openbsd net-tools curl jq && yum clean all # used by integration tests

# tools
RUN mkdir -p $HOME/.tools
RUN echo 'export PATH="$HOME/.tools:$PATH"' >> $HOME/.profile

# script to allow mapping framepointers on linux (until part of the toolchain)
RUN wget -q https://raw.githubusercontent.com/apple/swift/main/utils/symbolicate-linux-fatal -O $HOME/.tools/symbolicate-linux-fatal
RUN chmod 755 $HOME/.tools/symbolicate-linux-fatal

# swiftformat (until part of the toolchain)
ARG swiftformat_version=0.45.6
RUN git clone --branch $swiftformat_version --depth 1 https://github.com/nicklockwood/SwiftFormat $HOME/.tools/swift-format
RUN cd $HOME/.tools/swift-format && swift build -c release
RUN ln -s $HOME/.tools/swift-format/.build/release/swiftformat $HOME/.tools/swiftformat
