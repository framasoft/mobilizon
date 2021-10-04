import pkg_resources

def has_package(package):
    try:
        pkg_resources.get_distribution(package.decode('ascii'))
        return True
    except pkg_resources.DistributionNotFound:
        return False