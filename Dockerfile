FROM nixos/nix:2.26.2 AS build
WORKDIR /mnt/build
COPY . .
RUN --mount=type=cache,target=/nix,from=nixos/nix,source=/nix nix-build --verbose
RUN --mount=type=cache,target=/nix,from=nixos/nix,source=/nix cd ./result && tar cf /mnt/build/result.tar ./*
RUN mkdir /mnt/result && tar xf /mnt/build/result.tar --directory /mnt/result
CMD /mnt/result/bin/onix
