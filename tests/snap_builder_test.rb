require 'fileutils'
require 'github_snap_builder/snap_builder'
require_relative 'test_helpers'

module GithubSnapBuilder
	class SnapBuilderTest < SnapBuilderBaseTest
		def setup
			SnapBuilder.any_instance.stubs(:find_executable).with('snapcraft').returns('/snap/bin/snapcraft')
			Snap.any_instance.stubs(:find_executable).with('snapcraft').returns('/snap/bin/snapcraft')
			mock_repo = mock('repo')
			Rugged::Repository.stubs(:clone_at).with('test-url', '.').returns(mock_repo)
			mock_repo.stubs(:checkout)
		end

		def test_constructor
			SnapBuilder.new('foo', 'bar')
		end

		def test_missing_snapcraft_is_error
			SnapBuilder.any_instance.expects(:find_executable).with('snapcraft').returns('')
			assert_raise MissingSnapcraftError do
				SnapBuilder.new('foo', 'bar')
			end
		end

		def test_build
			builder = SnapBuilder.new('test-url', 'test-sha')
			builder.expects(:snapcraft).with() do
				FileUtils.touch('test.snap')
			end

			assert_instance_of Snap, builder.build()
		end

		def test_build_no_snaps
			builder = SnapBuilder.new('test-url', 'test-sha')
			builder.expects(:snapcraft).with('--destructive-mode')

			assert_raises BuildFailedError do
				builder.build()
			end
		end

		def test_build_no_new_snaps
			mock_repo = mock('repo')
			Rugged::Repository.expects(:clone_at).with('test-url', '.').returns(mock_repo)
			mock_repo.expects(:checkout).with('test-sha', {strategy: :force}) do
				# This existed before the build, so it should be factored out
				FileUtils.touch('test.snap')
			end

			builder = SnapBuilder.new('test-url', 'test-sha')
			builder.expects(:snapcraft).with('--destructive-mode')

			assert_raises BuildFailedError do
				builder.build()
			end
		end

		def test_build_multiple_snaps_takes_latest
			mock_repo = mock('repo')
			Rugged::Repository.expects(:clone_at).with('test-url', '.').returns(mock_repo)
			mock_repo.expects(:checkout).with('test-sha', {strategy: :force}) do
				FileUtils.touch('test1.snap')
			end

			builder = SnapBuilder.new('test-url', 'test-sha')
			builder.expects(:snapcraft).with() do
				FileUtils.touch('test2.snap')
			end

			assert_instance_of Snap, builder.build()
		end

		def test_build_multiple_snaps_built_error
			builder = SnapBuilder.new('test-url', 'test-sha')
			builder.expects(:snapcraft).with() do
				FileUtils.touch('test1.snap')
				FileUtils.touch('test2.snap')
			end

			assert_raises TooManySnapsError do
				builder.build()
			end
		end
	end
end