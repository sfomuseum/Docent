# https://github.com/ml-explore/mlx-swift?tab=readme-ov-file#xcodebuild

macos:
	xcodebuild -destination 'platform=macOS' -scheme docent -configuration Release

# https://swiftpackageindex.com/grpc/grpc-swift-protobuf/2.1.2/documentation/grpcprotobuf/code-generation-with-protoc

protoc:
	# rm Protos/docent_service/*.swift
	protoc \
		--swift_out=. \
		--swift_opt=Visibility=Public \
		--grpc-swift-2_out=. \
		--grpc-swift-2_opt=Visibility=Public \
		Protos/docent_service/docent_service.proto
